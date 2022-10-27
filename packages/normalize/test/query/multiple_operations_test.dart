import 'package:gql/language.dart';
import 'package:normalize/normalize.dart';
import 'package:test/test.dart';

import '../shared_data.dart';

void main() {
  group('Multiple Operations', () {
    test('With operationName', () async {
      final query = parseString('''
        query FirstQuery {
          author {
            id
          }
        }
        query TestQuery {
          posts {
            id
            author {
              id
              name
            }
            title
            comments {
              id
              commenter {
                id
                name
              }
            }
          }
        }
      ''');

      await expectLater(
        denormalizeOperation(
          document: query,
          read: (dataId) async => sharedNormalizedMap[dataId],
          operationName: 'TestQuery',
          addTypename: true,
        ),
        completion(equals(sharedResponse)),
      );

      final normalizedResult = {};
      await normalizeOperation(
        read: (dataId) async => normalizedResult[dataId],
        addTypename: true,
        write: (dataId, value) async => normalizedResult[dataId] = value,
        document: query,
        data: sharedResponse,
        operationName: 'TestQuery',
      );

      expect(
        normalizedResult,
        equals(sharedNormalizedMap),
      );
    });

    test('Without operationName', () async {
      final query = parseString('''
        query TestQuery {
          posts {
            id
            author {
              id
              name
            }
            title
            comments {
              id
              commenter {
                id
                name
              }
            }
          }
        }

        query FirstQuery {
          author {
            id
          }
        }
      ''');
      await expectLater(
        denormalizeOperation(
          document: query,
          read: (dataId) async => sharedNormalizedMap[dataId],
          addTypename: true,
        ),
        completion(equals(sharedResponse)),
      );

      final normalizedResult = {};
      await normalizeOperation(
        read: (dataId) async => normalizedResult[dataId],
        addTypename: true,
        write: (dataId, value) async => normalizedResult[dataId] = value,
        document: query,
        data: sharedResponse,
        operationName: 'TestQuery',
      );

      expect(
        normalizedResult,
        equals(sharedNormalizedMap),
      );
    });
  });
}
