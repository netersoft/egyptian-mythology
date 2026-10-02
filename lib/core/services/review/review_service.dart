import 'package:flutter/services.dart';

import '../../helpers/logging/log_helper.dart';

// Asks for a store rating with the in-app review sheet, at a moment the
// player is happy: right after beating one of their own records. The store
// decides whether the sheet actually shows (it enforces a per-user quota and
// never reports the outcome), so this is fire-and-forget -- the "Rate" button
// on AboutScreen stays the explicit way to reach the listing.
//
// The native side is a method channel in the app itself (MainActivity,
// AppDelegate), not the in_app_review plugin, whose Android build file
// doesn't build with AGP 9.
class ReviewService {
  // Lets the game-over screen and its "new record" banner appear first, so
  // the sheet doesn't cover the moment it's meant to follow.
  static const delay = Duration(seconds: 3);

  static const channel = MethodChannel('com.neteru.ankh/review');

  Future<void> requestAfterRecord() async {
    await Future<void>.delayed(delay);
    try {
      await channel.invokeMethod<bool>('requestReview');
    } on Exception catch (e, stackTrace) {
      // PlatformException, or MissingPluginException on a platform without
      // the channel: never worth more than a log line.
      LogHelper.w('In-app review request failed', error: e, stackTrace: stackTrace);
    }
  }
}
