import 'package:gql/language.dart';
import 'package:normalize/normalize.dart';
import 'package:test/test.dart';

void main() {
  group('Deep Null', () {
    final query = parseString('''
      query TestQuery {
        posts {
          id
          __typename
          author {
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
      'posts': [
        {
          'id': '123',
          '__typename': 'Post',
          'author': {'id': '1', '__typename': 'Author', 'name': 'Paul'},
          'title': 'My awesome blog post',
          'comments': null
        }
      ]
    };

    final normalizedMap = {
      'Query': {
        'posts': [
          {'\$ref': 'Post:123'}
        ]
      },
      'Post:123': {
        'id': '123',
        '__typename': 'Post',
        'author': {'\$ref': 'Author:1'},
        'title': 'My awesome blog post',
        'comments': null
      },
      'Author:1': {'id': '1', '__typename': 'Author', 'name': 'Paul'}
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
        equals(normalizedMap),
      );
    });

    test('Produces correct nested data object', () async {
      await expectLater(
        denormalizeOperation(
          document: query,
          read: (dataId) async => normalizedMap[dataId],
        ),
        completion(equals(data)),
      );
    });
  });
}
