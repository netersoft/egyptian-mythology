import 'package:egyptian_mythology/core/services/review/review_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:mocktail/mocktail.dart';

class _MockInAppReview extends Mock implements InAppReview {}

void main() {
  late _MockInAppReview inAppReview;
  late ReviewService service;

  setUp(() {
    inAppReview = _MockInAppReview();
    when(() => inAppReview.requestReview()).thenAnswer((_) async {});
    service = ReviewService(inAppReview: inAppReview);
  });

  group('ReviewService', () {
    test('requests a review once the game-over screen had time to show', () {
      when(() => inAppReview.isAvailable()).thenAnswer((_) async => true);

      fakeAsync((async) {
        service.requestAfterRecord();
        async.elapse(ReviewService.delay - const Duration(milliseconds: 1));
        verifyNever(() => inAppReview.requestReview());

        async.elapse(const Duration(milliseconds: 1));
        verify(() => inAppReview.requestReview()).called(1);
      });
    });

    test('does nothing when in-app review is unavailable', () {
      when(() => inAppReview.isAvailable()).thenAnswer((_) async => false);

      fakeAsync((async) {
        service.requestAfterRecord();
        async.elapse(ReviewService.delay);
        verifyNever(() => inAppReview.requestReview());
      });
    });

    test('swallows a platform failure instead of crashing the game over', () {
      when(() => inAppReview.isAvailable()).thenThrow(Exception('Play Store missing'));

      fakeAsync((async) {
        Object? error;
        var done = false;
        service.requestAfterRecord().then(
          (_) => done = true,
          onError: (Object e) {
            error = e;
            return false;
          },
        );
        async.elapse(ReviewService.delay);

        expect(error, isNull);
        expect(done, isTrue);
      });
    });
  });
}
