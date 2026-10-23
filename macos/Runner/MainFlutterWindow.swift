import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController
    configureStartupFrame()

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  private func configureStartupFrame() {
    guard let screen = self.screen ?? NSScreen.main else { return }
    let frame = screen.visibleFrame.insetBy(dx: 12, dy: 12)
    self.minSize = NSSize(
      width: min(1100, frame.width),
      height: min(700, frame.height)
    )
    self.setFrame(frame, display: true)
  }
}
