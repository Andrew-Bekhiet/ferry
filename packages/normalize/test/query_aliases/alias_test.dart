import 'package:gql/language.dart';
import 'package:normalize/normalize.dart';
import 'package:test/test.dart';

import '../shared_data.dart';

void main() {
  group('Alias', () {
    final query = parseString('''
      query TestQuery {
        __typename
        posts {
          id
          __typename
          olle: author {
            id
            __typename
            name
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

    final data = {
      '__typename': 'Query',
      'posts': [
        {
          'id': '123',
          '__typename': 'Post',
          'olle': {'id': '1', '__typename': 'Author', 'name': 'Paul'},
          'title': 'My awesome blog post',
          'comments': [
            {
              'id': '324',
              '__typename': 'Comment',
              'commenter': {'id': '2', '__typename': 'Author', 'name': 'Nicole'}
            }
          ]
        }
      ]
    };

    test('Produces correct normalized object', () async {
      final normalizedResult = {};
      await normalizeOperation(
        read: (dataId) async => normalizedResult[dataId],
        write: (dataId, value) async => normalizedResult[dataId] = value,
        document: query,
        data: data,
      );

      expect(
        normalizedResult,
        equals(sharedNormalizedMap),
      );
    });

    test('Produces correct nested data object', () async {
      await expectLater(
        denormalizeOperation(
          document: query,
          read: (dataId) async => sharedNormalizedMap[dataId],
        ),
        completion(equals(data)),
      );
    });
  });
}
