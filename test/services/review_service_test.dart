import 'package:egyptian_mythology/core/services/review/review_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> calls;

  void mockChannel(Future<Object?> Function(MethodCall call) handler) =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(ReviewService.channel, (call) {
        calls.add(call.method);
        return handler(call);
      });

  setUp(() => calls = []);

  tearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(ReviewService.channel, null));

  group('ReviewService', () {
    test('asks the native side for a review once the game-over screen had time to show', () {
      mockChannel((_) async => true);

      fakeAsync((async) {
        ReviewService().requestAfterRecord();
        async.elapse(ReviewService.delay - const Duration(milliseconds: 1));
        expect(calls, isEmpty);

        async
          ..elapse(const Duration(milliseconds: 1))
          ..flushMicrotasks();
        expect(calls, ['requestReview']);
      });
    });

    test('swallows a platform failure instead of crashing the game over', () {
      mockChannel((_) async => throw PlatformException(code: 'ERROR'));

      fakeAsync((async) {
        Object? error;
        var done = false;
        ReviewService().requestAfterRecord().then(
          (_) => done = true,
          onError: (Object e) {
            error = e;
            return false;
          },
        );
        async
          ..elapse(ReviewService.delay)
          ..flushMicrotasks();

        expect(error, isNull);
        expect(done, isTrue);
      });
    });

    test('swallows a missing native side (platform without the channel)', () {
      mockChannel((_) async => throw MissingPluginException());

      fakeAsync((async) {
        Object? error;
        var done = false;
        ReviewService().requestAfterRecord().then(
          (_) => done = true,
          onError: (Object e) {
            error = e;
            return false;
          },
        );
        async
          ..elapse(ReviewService.delay)
          ..flushMicrotasks();

        expect(error, isNull);
        expect(done, isTrue);
      });
    });
  });
}
