import 'package:ferry_cache/ferry_cache.dart';
import 'package:ferry_test_graphql/queries/__generated__/human_with_args.data.gql.dart';
import 'package:ferry_test_graphql/queries/__generated__/human_with_args.req.gql.dart';
import 'package:normalize/src/utils/field_key.dart';
import 'package:test/test.dart';

void main() {
  final chewieReq = GHumanWithArgsReq((b) => b..vars.id = 'chewie');

  final chewieData = GHumanWithArgsData(
    (b) => b
      ..human.id = 'chewie'
      ..human.name = 'Chewie'
      ..human.height = 2.3,
  );

  final lukeData = GHumanWithArgsData(
    (b) => b
      ..human.id = 'luke'
      ..human.name = 'Luke Skywalker'
      ..human.height = 1.6,
  );

  final hanReq = GHumanWithArgsReq((b) => b..vars.id = 'han-solo');

  final hanData = GHumanWithArgsData(
    (b) => b
      ..human.id = 'han'
      ..human.name = 'Han Solo'
      ..human.height = 1.89
      ..human.friendsConnection.friends.addAll([
        GHumanWithArgsData_human_friendsConnection_friends.fromJson(
          lukeData.human.toJson(),
        )!,
        GHumanWithArgsData_human_friendsConnection_friends.fromJson(
          chewieData.human.toJson(),
        )!,
      ]),
  );
  group('Evicting entities', () {
    test('can evict entities', () async {
      final cache = Cache();
      await cache.writeQuery(hanReq, hanData);
      await cache.writeQuery(chewieReq, chewieData);
      await expectLater(cache.readQuery(hanReq), completion(equals(hanData)));
      final entityId = cache.identify(hanData.human)!;
      await cache.evict(entityId);
      await expectLater(cache.readQuery(hanReq), completion(equals(null)));
      expect(cache.store.get(entityId), equals(null));
      await expectLater(
          cache.readQuery(chewieReq), completion(equals(chewieData)));
    });

    test('can evict entities optimistically', () async {
      final cache = Cache();
      await cache.writeQuery(hanReq, hanData);
      await expectLater(cache.readQuery(hanReq), completion(equals(hanData)));
      final entityId = cache.identify(hanData.human)!;
      await cache.evict(
        entityId,
        optimisticRequest: hanReq,
      );
      await expectLater(
          cache.readQuery(hanReq, optimistic: true), completion(equals(null)));
      await expectLater(cache.readQuery(hanReq, optimistic: false),
          completion(equals(hanData)));
      expect(cache.store.get(entityId), isNotNull);
    });

    test('can filter out dangling references', () async {
      final cache = Cache();
      await cache.writeQuery(hanReq, hanData);
      expect(
        (await cache.readQuery(hanReq))!
            .human
            .friendsConnection
            .friends!
            .length,
        equals(2),
      );
      await cache.evict(cache.identify(chewieData.human)!);
      expect(
        (await cache.readQuery(hanReq))!
            .human
            .friendsConnection
            .friends!
            .length,
        equals(1),
      );
    });
  });

  group('Evicting fields', () {
    test('can evict fields', () async {
      final cache = Cache();
      await cache.writeQuery(hanReq, hanData);
      final entityId = cache.identify(hanData.human)!;
      await cache.evict(entityId, fieldName: 'height');
      final result = cache.readQuery(hanReq);
      expect(result,
          completion(equals(hanData.rebuild((b) => b..human.height = null))));
    });

    test('can evict fields optimistically', () async {
      final cache = Cache();
      await cache.writeQuery(hanReq, hanData);
      final entityId = cache.identify(hanData.human)!;
      await cache.evict(
        entityId,
        fieldName: 'height',
        optimisticRequest: hanReq,
      );
      final optimisticResult = cache.readQuery(hanReq, optimistic: true);
      await expectLater(
        optimisticResult,
        completion(equals(hanData.rebuild((b) => b..human.height = null))),
      );
      final nonOptimisticResult = cache.readQuery(hanReq, optimistic: false);
      await expectLater(
        nonOptimisticResult,
        completion(equals(hanData)),
      );
    });

    test('can evict only fields that include specific args', () async {
      final cache = Cache();
      await cache.writeQuery(
        hanReq.rebuild((b) => b..vars.friendsAfter = 'luke'),
        hanData,
      );
      await cache.writeQuery(
        hanReq.rebuild((b) => b..vars.friendsAfter = 'chewie'),
        hanData,
      );
      final entityId = cache.identify(hanData.human)!;
      final keyLuke =
          FieldKey.from('friendsConnection', {'first': 10, 'after': 'luke'});
      final keyChewie =
          FieldKey.from('friendsConnection', {'first': 10, 'after': 'chewie'});
      expect((await cache.store.get(entityId))![keyLuke.toString()], isNotNull);
      expect(
          (await cache.store.get(entityId))![keyChewie.toString()], isNotNull);
      await cache.evict(entityId,
          fieldName: 'friendsConnection', args: {'after': 'luke'});
      expect((await cache.store.get(entityId))![keyLuke.toString()], isNull);
      expect(
          (await cache.store.get(entityId))![keyChewie.toString()], isNotNull);
    });
  });

  group('Garbage collection', () {
    test('can remove orphaned entities', () async {
      final cache = Cache();
      await cache.writeQuery(hanReq, hanData);
      await cache.writeQuery(
        hanReq,
        hanData.rebuild((b) => b..human.friendsConnection.friends.removeLast()),
      );
      expect(cache.store.get('Human:luke'), isNotNull);
      expect(cache.store.get('Human:chewie'), isNotNull);
      await cache.gc();
      expect(cache.store.get('Human:luke'), isNotNull);
      expect(cache.store.get('Human:chewie'), isNull);
    });

    test('can retain and release entities', () async {
      final cache = Cache();
      await cache.writeQuery(hanReq, hanData);
      await cache.writeQuery(
        hanReq,
        hanData.rebuild((b) => b..human.friendsConnection.friends.removeLast()),
      );
      expect(await cache.store.get('Human:luke'), isNotNull);
      expect(await cache.store.get('Human:chewie'), isNotNull);
      cache.retain('Human:chewie');
      await cache.gc();
      expect(await cache.store.get('Human:luke'), isNotNull);
      expect(await cache.store.get('Human:chewie'), isNotNull);
      cache.release('Human:chewie');
      await cache.gc();
      expect(await cache.store.get('Human:luke'), isNotNull);
      expect(await cache.store.get('Human:chewie'), isNull);
    });
  });
}
