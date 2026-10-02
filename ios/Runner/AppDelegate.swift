import UIKit
import Flutter
import StoreKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    registerReviewChannel()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // App Store in-app review, called by ReviewService (the Android side lives
  // in MainActivity). Apple decides whether the prompt shows, so this always
  // answers true once asked.
  private func registerReviewChannel() {
    guard let registrar = registrar(forPlugin: "ReviewChannel") else { return }
    let channel = FlutterMethodChannel(name: "com.neteru.ankh/review", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard call.method == "requestReview" else {
        result(FlutterMethodNotImplemented)
        return
      }
      if #available(iOS 14.0, *),
        let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
        SKStoreReviewController.requestReview(in: scene)
      } else {
        SKStoreReviewController.requestReview()
      }
      result(true)
    }
  }
}
