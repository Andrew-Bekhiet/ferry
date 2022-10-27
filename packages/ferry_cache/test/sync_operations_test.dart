import 'package:ferry_cache/ferry_cache.dart';
import 'package:ferry_test_graphql/fragments/__generated__/review_fragment.data.gql.dart';
import 'package:ferry_test_graphql/fragments/__generated__/review_fragment.req.gql.dart';
import 'package:ferry_test_graphql/queries/__generated__/reviews.data.gql.dart';
import 'package:ferry_test_graphql/queries/__generated__/reviews.req.gql.dart';
import 'package:test/test.dart';

final reviewsReq = GReviewsReq();

final review = GReviewsData_reviews(
  (b) => b
    ..id = '123'
    ..stars = 4
    ..commentary = 'Pretty Good',
);

final reviewsData = GReviewsData(
  (b) => b..reviews.add(review),
);

final reviewFragmentReq =
    GReviewFragmentReq((b) => b..idFields = {'id': review.id});

final reviewFragmentData = GReviewFragmentData.fromJson(review.toJson());

void main() {
  group('sync operations', () {
    test('can read and write queries', () async {
      final cache = Cache();
      await cache.writeQuery(reviewsReq, reviewsData);
      await expectLater(
          cache.readQuery(reviewsReq), completion(equals(reviewsData)));
    });

    test('can read fragments written by queries', () async {
      final cache = Cache();
      await cache.writeQuery(reviewsReq, reviewsData);
      await expectLater(cache.readFragment(reviewFragmentReq),
          completion(equals(reviewFragmentData)));
    });

    test('can read and write fragments', () async {
      final cache = Cache();
      await cache.writeFragment(reviewFragmentReq, reviewFragmentData);
      await expectLater(cache.readFragment(reviewFragmentReq),
          completion(equals(reviewFragmentData)));
    });

    test('dataIdFromObject overrides cache.identify', () {
      final cache = Cache(dataIdFromObject: (object) => 'OVERRIDE');
      expect(cache.identify(reviewFragmentData), equals('OVERRIDE'));
    });

    test('can read and write with a data id override', () async {
      final cache = Cache(dataIdFromObject: (object) => 'OVERRIDE');
      await cache.writeFragment(reviewFragmentReq, reviewFragmentData);

      reviewFragmentReq.idFields['id'] = 'OVERRIDE';

      await expectLater(cache.readFragment(reviewFragmentReq),
          completion(equals(reviewFragmentData)));
    });

    test('can clear cache', () async {
      final cache = Cache();

      await cache.writeQuery(reviewsReq, reviewsData);
      await expectLater(
        cache.readQuery(reviewsReq),
        completion(equals(reviewsData)),
      );

      cache.clear();
      await expectLater(
        cache.readQuery(reviewsReq),
        completion(equals(null)),
      );
    });
  });
}
