import 'package:gql/language.dart';
import 'package:normalize/normalize.dart';
import 'package:test/test.dart';

import '../shared_data.dart';

void main() {
  group('Variables Int Simple', () {
    final query = parseString('''
      query TestQuery {
        __typename
        posts {
          id
          __typename
          author {
            id
            __typename
            name
          }
          title
          comments(a: 1) {
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

    final normalizedMap = {
      'Query': {
        '__typename': 'Query',
        'posts': [
          {'\$ref': 'Post:123'}
        ]
      },
      'Post:123': {
        'id': '123',
        '__typename': 'Post',
        'author': {'\$ref': 'Author:1'},
        'title': 'My awesome blog post',
        'comments({"a":1})': [
          {'\$ref': 'Comment:324'}
        ]
      },
      'Author:1': {'id': '1', '__typename': 'Author', 'name': 'Paul'},
      'Comment:324': {
        'id': '324',
        '__typename': 'Comment',
        'commenter': {'\$ref': 'Author:2'}
      },
      'Author:2': {'id': '2', '__typename': 'Author', 'name': 'Nicole'}
    };

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
        equals(normalizedMap),
      );
    });

    test('Produces correct nested data object', () async {
      await expectLater(
        denormalizeOperation(
          document: query,
          read: (dataId) async => normalizedMap[dataId],
        ),
        completion(equals(sharedResponse)),
      );
    });
  });
}
