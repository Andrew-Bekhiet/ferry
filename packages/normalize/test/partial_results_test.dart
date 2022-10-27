import 'package:gql/language.dart';
import 'package:normalize/normalize.dart';
import 'package:test/test.dart';

void main() {
  test('Return partial data', () async {
    final data = {
      'Query': {
        'posts': [
          {'\$ref': 'Post:123'}
        ]
      },
      'Post:123': {
        'id': '123',
        '__typename': 'Post',
      },
    };

    final query = parseString('''
      query TestQuery {
        posts {
          id
          title
        }
      }
    ''');
    final response = {
      'posts': [
        {
          'id': '123',
          '__typename': 'Post',
        }
      ]
    };
    await expectLater(
      denormalizeOperation(
        document: query,
        read: (dataId) async => data[dataId],
        addTypename: true,
        returnPartialData: true,
      ),
      completion(equals(response)),
    );
  });

  test("Don't return partial data", () async {
    final data = {
      'Query': {
        'posts': [
          {'\$ref': 'Post:123'}
        ]
      },
      'Post:123': {
        'id': '123',
        '__typename': 'Post',
      },
    };

    final query = parseString('''
      query TestQuery {
        posts {
          id
          title
        }
      }
    ''');
    await expectLater(
      denormalizeOperation(
        document: query,
        read: (dataId) async => data[dataId],
        addTypename: true,
        returnPartialData: false,
      ),
      completion(equals(null)),
    );
  });

  test('Explicit null', () async {
    final data = {
      'Query': {
        '__typename': 'Query',
        'posts': [
          {'\$ref': 'Post:123'}
        ]
      },
      'Post:123': {
        'id': '123',
        'title': null,
        '__typename': 'Post',
      },
    };
    final query = parseString('''
      query TestQuery {
        posts {
          id
          title
        }
      }
    ''');
    final response = {
      '__typename': 'Query',
      'posts': [
        {
          'id': '123',
          '__typename': 'Post',
          'title': null,
        }
      ]
    };
    await expectLater(
      denormalizeOperation(
        document: query,
        read: (dataId) async => data[dataId],
        addTypename: true,
        returnPartialData: false,
      ),
      completion(equals(response)),
    );
  });
}
