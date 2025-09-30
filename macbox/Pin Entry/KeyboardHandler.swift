import SwiftUI

public enum KeyInput {
    case digit(String)
    case backspace
    case returnKey
    case escape
}

struct KeyboardHandler: NSViewRepresentable {
    let onKeyPressed: (KeyInput) -> Void
    
    func makeNSView(context: Context) -> KeyboardHandlerView {
        let view = KeyboardHandlerView()
        view.onKeyPressed = onKeyPressed
        return view
    }
    
    func updateNSView(_ nsView: KeyboardHandlerView, context: Context) {
        nsView.onKeyPressed = onKeyPressed
    }
}

class KeyboardHandlerView: NSView {
    var onKeyPressed: ((KeyInput) -> Void)?
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
    
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return event
        }

        DispatchQueue.main.async {
            self.window?.makeFirstResponder(self.window?.contentView)
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        let key = event.charactersIgnoringModifiers ?? ""
        
        if key.count == 1 && key.first!.isNumber {
            onKeyPressed?(.digit(key))
        } else {
            switch event.keyCode {
            case 51: 
                onKeyPressed?(.backspace)
            case 36: 
                onKeyPressed?(.returnKey)
            case 53: 
                onKeyPressed?(.escape)
            default:
                break
            }
        }
    }
}
