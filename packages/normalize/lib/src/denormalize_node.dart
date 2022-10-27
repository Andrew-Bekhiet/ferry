import 'package:gql/ast.dart';
import 'package:normalize/src/config/normalization_config.dart';
import 'package:normalize/src/policies/field_policy.dart';
import 'package:normalize/src/utils/exceptions.dart';
import 'package:normalize/src/utils/expand_fragments.dart';
import 'package:normalize/src/utils/field_key.dart';
import 'package:normalize/src/utils/is_dangling_reference.dart';

/// Returns a denormalized object for a given [SelectionSetNode].
///
/// This is called recursively as the AST is traversed.
Future<Object?> denormalizeNode({
  required SelectionSetNode? selectionSet,
  required Object? dataForNode,
  required NormalizationConfig config,
}) async {
  if (dataForNode == null) return null;

  if (dataForNode is List) {
    // A unique object to flag removed items
    //
    // since we cannot filter the list asynchronously,
    // we return this object for each excluded item
    // then filter on it later after awaiting all the futures using [Future.wait]
    final excludedFlag = Object();

    return (await Future.wait(
      dataForNode.map(
        (data) async {
          if (!await isDanglingReference(data, config)) {
            return denormalizeNode(
              selectionSet: selectionSet,
              dataForNode: data,
              config: config,
            );
          }

          return excludedFlag;
        },
      ),
    ))
        .where((o) => !identical(o, excludedFlag))
        .toList();
  }

  // If this is a leaf node, return the data
  if (selectionSet == null) return dataForNode;

  if (dataForNode is Map) {
    final denormalizedData = dataForNode.containsKey(config.referenceKey)
        ? await config.read(dataForNode[config.referenceKey]) ?? {}
        : Map<String, dynamic>.from(dataForNode);

    final typename = denormalizedData['__typename'];
    final typePolicy = config.typePolicies[typename];

    final subNodes = expandFragments(
      typename: typename,
      selectionSet: selectionSet,
      fragmentMap: config.fragmentMap,
      possibleTypes: config.possibleTypes,
    );

    final resultFutures = subNodes.fold<Map<String, dynamic>>(
      {},
      (result, fieldNode) {
        final fieldPolicy =
            (typePolicy?.fields ?? const {})[fieldNode.name.value];
        final policyCanRead = fieldPolicy?.read != null;

        final fieldName = FieldKey(
          fieldNode,
          config.variables,
          fieldPolicy,
        ).toString();

        final resultKey = fieldNode.alias?.value ?? fieldNode.name.value;

        /// If the policy can't read,
        /// and the key is missing from the data,
        /// we have partial data
        if (!policyCanRead && !denormalizedData.containsKey(fieldName)) {
          if (config.allowPartialData) {
            return result;
          }
          throw PartialDataException(path: [resultKey]);
        }

        try {
          return result
            ..[resultKey] = Future(
              () async {
                if (policyCanRead) {
                  // we can denormalize missing fields with policies
                  // because they may be purely virtualized
                  return await fieldPolicy!.read!(
                    denormalizedData[fieldName],
                    FieldFunctionOptions(
                      field: fieldNode,
                      config: config,
                    ),
                  );
                }
                return denormalizeNode(
                  selectionSet: fieldNode.selectionSet,
                  dataForNode: denormalizedData[fieldName],
                  config: config,
                );
              },
            ).onError<PartialDataException>(
              (e, _) => throw PartialDataException(
                path: [fieldName, ...e.path],
              ),
            );
        } on PartialDataException catch (e) {
          throw PartialDataException(path: [fieldName, ...e.path]);
        }
      },
    );

    // Reconstruct the data again in the same order
    // after awaiting all pending futures
    final result = Map.fromEntries(
      await Future.wait(
        resultFutures.entries.map(
          (e) async => MapEntry(e.key, await e.value),
        ),
      ),
    );

    return result.isEmpty ? null : result;
  }

  throw Exception(
    'There are sub-selections on this node, but the data is not null, an Array, or a Map',
  );
}
