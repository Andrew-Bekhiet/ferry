import 'package:gql/language.dart';
import 'package:normalize/normalize.dart';
import 'package:test/test.dart';

void main() {
  group('FieldPolicy.read', () {
    test('can use custom read function on root field', () async {
      final query = parseString('''
        query TestQuery {
          posts {
            id
            title
          }
        }
      ''');

      final normalized = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {'\$ref': 'Post:123'},
            {'\$ref': 'Post:456'},
          ]
        },
        'Post:123': {
          'id': '123',
          '__typename': 'Post',
        },
        'Post:456': {
          'id': '456',
          '__typename': 'Post',
        },
      };

      final result = {
        '__typename': 'Query',
        'posts': [
          {
            'id': '123',
            '__typename': 'Post',
          },
        ]
      };

      await expectLater(
        denormalizeOperation(
          addTypename: true,
          document: query,
          read: (dataId) async => normalized[dataId],
          typePolicies: {
            'Query': TypePolicy(
              queryType: true,
              fields: {
                'posts': FieldPolicy(
                  read: (existing, options) async => (await options
                          .readField<List>(options.field, existing ?? []))!
                      .where((post) => post['id'] == '123')
                      .toList(),
                )
              },
            ),
          },
        ),
        completion(equals(result)),
      );
    });

    test('can use custom read function on child field', () async {
      final query = parseString('''
        query TestQuery {
          posts {
            id
            title
          }
        }
      ''');

      final normalized = {
        'Query': {
          '__typename': 'Query',
          'posts': [
            {'\$ref': 'Post:123'},
          ]
        },
        'Post:123': {
          'id': '123',
          '__typename': 'Post',
          'title': 'My awesome blog post',
        },
      };

      final result = {
        '__typename': 'Query',
        'posts': [
          {
            'id': '123',
            '__typename': 'Post',
            'title': 'MY AWESOME BLOG POST',
          }
        ]
      };

      await expectLater(
        denormalizeOperation(
          addTypename: true,
          document: query,
          read: (dataId) async => normalized[dataId],
          typePolicies: {
            'Post': TypePolicy(
              fields: {
                'title': FieldPolicy(
                  read: (existing, options) => existing.toUpperCase(),
                )
              },
            ),
          },
        ),
        completion(equals(result)),
      );
    });
  });
}
