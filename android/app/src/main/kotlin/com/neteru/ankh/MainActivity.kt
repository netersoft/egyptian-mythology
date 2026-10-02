package com.neteru.ankh

import com.google.android.play.core.review.ReviewManagerFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Play in-app review, called by ReviewService. Done here rather than with
    // the in_app_review plugin, whose build file applies kotlin-android and
    // breaks the AGP 9 build. Answers true once the review flow has run --
    // Google never says whether the sheet was actually shown -- and false when
    // the flow couldn't start (no Play Store, not installed from Play...).
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.neteru.ankh/review").setMethodCallHandler { call, result ->
            if (call.method != "requestReview") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val manager = ReviewManagerFactory.create(this)
            manager.requestReviewFlow().addOnCompleteListener { request ->
                if (!request.isSuccessful) {
                    result.success(false)
                    return@addOnCompleteListener
                }
                manager.launchReviewFlow(this, request.result).addOnCompleteListener { result.success(true) }
            }
        }
    }
}
