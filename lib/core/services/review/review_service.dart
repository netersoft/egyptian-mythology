import 'package:in_app_review/in_app_review.dart';

import '../../helpers/logging/log_helper.dart';

// Asks for a Play Store rating with the in-app review sheet, at a moment the
// player is happy: right after beating one of their own records. Google
// decides whether the sheet actually shows (it enforces a per-user quota and
// never reports the outcome), so this is fire-and-forget -- the "Rate" button
// on AboutScreen stays the explicit way to reach the listing.
class ReviewService {
  // Lets the game-over screen and its "new record" banner appear first, so
  // the sheet doesn't cover the moment it's meant to follow.
  static const delay = Duration(seconds: 3);

  final InAppReview _inAppReview;

  ReviewService({InAppReview? inAppReview}) : _inAppReview = inAppReview ?? InAppReview.instance;

  Future<void> requestAfterRecord() async {
    await Future<void>.delayed(delay);
    try {
      if (await _inAppReview.isAvailable()) await _inAppReview.requestReview();
    } on Exception catch (e, stackTrace) {
      LogHelper.w('In-app review request failed', error: e, stackTrace: stackTrace);
    }
  }
}
