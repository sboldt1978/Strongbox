import SwiftUI
import Cocoa

@objc class SimplePinModal: NSObject {
    private static var currentWindow: NSWindow?
    private static weak var currentDelegate: AnyObject?
    
    @objc static func showFrom(_ viewController: NSViewController, delegate: AnyObject) {
        currentDelegate = delegate
        
        let pinView = SimplePinView(
            onPinSubmitted: { pin in
                if let delegate = currentDelegate as? NSObject,
                   delegate.responds(to: #selector(SimplePinModalDelegate.simplePinModalDidSubmitPin(_:))) {
                    delegate.perform(#selector(SimplePinModalDelegate.simplePinModalDidSubmitPin(_:)), with: pin)
                }
                dismissModal()
            },
            onDismiss: {
                if let delegate = currentDelegate as? NSObject,
                   delegate.responds(to: #selector(SimplePinModalDelegate.simplePinModalDidCancel)) {
                    delegate.perform(#selector(SimplePinModalDelegate.simplePinModalDidCancel))
                }
                dismissModal()
            }
        )
        showPinModal(with: pinView, from: viewController)
    }
    
    @objc static func dismissModal() {
        if let window = currentWindow {
            window.sheetParent?.endSheet(window)
            currentWindow = nil
            currentDelegate = nil
        }
    }
}

private extension SimplePinModal {
    static func showPinModal(with pinView: SimplePinView, from viewController: NSViewController) {
        let hostingController = NSHostingController(rootView: pinView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 350),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.contentViewController = hostingController
        window.center()
        window.isMovable = false
        window.backgroundColor = NSColor.clear
        
        currentWindow = window
        
        viewController.view.window?.beginSheet(window) { _ in
            currentWindow = nil
            currentDelegate = nil
        }
    }
}
