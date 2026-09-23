import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, FlutterStreamHandler {
  private var volumeSink: FlutterEventSink?
  private var volumeObservation: NSKeyValueObservation?
  private var previousVolume: Float = 0

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    volumeSink = events
    let session = AVAudioSession.sharedInstance()
    try? session.setActive(true)
    previousVolume = session.outputVolume
    volumeObservation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
      guard let self, let volume = change.newValue, volume != self.previousVolume else { return }
      let direction = volume > self.previousVolume ? 1 : -1
      self.previousVolume = volume
      DispatchQueue.main.async { self.volumeSink?(direction) }
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    volumeObservation?.invalidate()
    volumeObservation = nil
    volumeSink = nil
    return nil
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    FlutterEventChannel(name: "keihatsu/reader_volume", binaryMessenger: engineBridge.applicationRegistrar.messenger()).setStreamHandler(self)
  }
}
