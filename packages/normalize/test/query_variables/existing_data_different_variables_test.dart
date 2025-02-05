import 'package:gql/language.dart';
import 'package:normalize/normalize.dart';
import 'package:test/test.dart';

void main() {
  group('Existing data different variables', () {
    final query = parseString('''
      query TestQuery(\$a: Boolean) {
        posts(b: \$a) {
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

    test('With no data', () async {
      final normalizedMap = {};
      await expectLater(
        denormalizeOperation(
          document: query,
          read: (dataId) async => normalizedMap[dataId],
          variables: {'a': false},
        ),
        completion(equals(null)),
      );
    });

    test('With data that uses different variables', () async {
      final normalizedMap = {
        'Query': {
          'posts({"b":true})': [
            {'\$ref': 'Post:123'}
          ]
        },
        'Post:123': {
          'id': '123',
          '__typename': 'Post',
          'author': {'\$ref': 'Author:1'},
          'title': 'My awesome blog post',
          'comments': [
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

      await expectLater(
        denormalizeOperation(
            document: query,
            read: (dataId) async => normalizedMap[dataId],
            variables: {'a': false}),
        completion(equals(null)),
      );
    });

    test('Explicit null', () async {
      final normalizedMap = {
        'Query': {'posts({"b":false})': null},
      };

      await expectLater(
        denormalizeOperation(
            document: query,
            read: (dataId) async => normalizedMap[dataId],
            variables: {'a': false}),
        completion(equals({'posts': null})),
      );
    });
  });
  group('Existing data different nested variables', () {
    final query = parseString('''
      query TestQuery(\$a: Boolean) {
        posts {
          id
          __typename
          author {
            id
            __typename
            name
          }
          title
          comments(b: \$a) {
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

    test('With data that uses different nested variables', () async {
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
          'comments({"b":true})': [
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

      final response = {
        'posts': [
          {
            'id': '123',
            '__typename': 'Post',
            'author': {'id': '1', '__typename': 'Author', 'name': 'Paul'},
            'title': 'My awesome blog post',
          }
        ]
      };

      await expectLater(
        denormalizeOperation(
          document: query,
          read: (dataId) async => normalizedMap[dataId],
          returnPartialData: true,
          variables: {'a': false},
        ),
        completion(equals(response)),
      );
    });

    test('Explicit null', () async {
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
          'comments({"b":true})': [
            {'\$ref': 'Comment:324'}
          ],
          'comments({"b":false})': null
        },
        'Author:1': {'id': '1', '__typename': 'Author', 'name': 'Paul'},
        'Comment:324': {
          'id': '324',
          '__typename': 'Comment',
          'commenter': {'\$ref': 'Author:2'}
        },
        'Author:2': {'id': '2', '__typename': 'Author', 'name': 'Nicole'}
      };

      final response = {
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

      await expectLater(
        denormalizeOperation(
          document: query,
          read: (dataId) async => normalizedMap[dataId],
          variables: {'a': false},
        ),
        completion(equals(response)),
      );
    });
  });
}
