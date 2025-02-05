import 'package:gql/language.dart';
import 'package:normalize/normalize.dart';
import 'package:test/test.dart';

import '../shared_data.dart';

void main() {
  group('Inline Fragment', () {
    final query = parseString('''
      query TestQuery {
        __typename
        posts {
          id
          __typename
          ... on Post {
            author {
              ... on Author {
                id
                __typename
                name
              }
            }
          }
          title
          comments {
            id
            __typename
            commenter {
              id
              __typename
              name
            }
          }
        }
      }
    ''');

    test('Produces correct normalized object', () async {
      final normalizedResult = {};
      await normalizeOperation(
        read: (dataId) async => normalizedResult[dataId],
        write: (dataId, value) async => normalizedResult[dataId] = value,
        document: query,
        data: sharedResponse,
      );

      expect(
        normalizedResult,
        equals(sharedNormalizedMap),
      );
    });

    test('Produces correct nested data object', () async {
      expect(
        denormalizeOperation(
          document: query,
          read: (dataId) async => sharedNormalizedMap[dataId],
        ),
        completion(equals(sharedResponse)),
      );
    });
  });
}
