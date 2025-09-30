import SwiftUI
import Cocoa

@objc protocol SimplePinModalDelegate: NSObjectProtocol {
    func simplePinModalDidSubmitPin(_ pin: String)
    func simplePinModalDidCancel()
}

struct SimplePinView: View {
    @State private var pinDigits: [String] = ["", "", "", ""]
    let maxDigits: Int = 4
    let onPinSubmitted: (String) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: {
                    onDismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(width: 24, height: 24)
                .background(Color.gray.opacity(0.1))
                .clipShape(Circle())
            }
            .padding(.top, 16)
            .padding(.trailing, 16)

            VStack(spacing: 10) {
                Text(NSLocalizedString("database_pin_title", comment: "Database Pin"))
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(NSLocalizedString("database_pin_subtitle", comment: "Enter the 4-digit Database Pin code"))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, 20)
        
            HStack(spacing: 15) {
                ForEach(0..<maxDigits, id: \.self) { index in
                    PinDigitBox(
                        digit: $pinDigits[index],
                        isActive: index == getCurrentActiveIndex()
                    )
                }
            }
            .padding(.top, 30)
            .padding(.bottom, 40)
            
            Spacer()
        
            Button(action: {
                handleSubmit()
            }) {
                Text(NSLocalizedString("generic_done", comment: "Done"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(pinDigits.joined().count == maxDigits ? Color.blue : Color.gray)
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(pinDigits.joined().count != maxDigits)
            .animation(.snappy, value: pinDigits.joined().count == maxDigits)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(width: 400, height: 350)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .background(KeyboardHandler { keyInput in
            handleKeyInput(keyInput)
        })
    }
    
    
}

private extension SimplePinView {
    func getCurrentActiveIndex() -> Int {
        return pinDigits.firstIndex(where: { $0.isEmpty }) ?? maxDigits
    }
    
    func addDigit(_ digit: String) {
        if let emptyIndex = pinDigits.firstIndex(where: { $0.isEmpty }) {
            pinDigits[emptyIndex] = digit
        }
    }
    
    func removeDigit() {
        if let lastFilledIndex = pinDigits.lastIndex(where: { !$0.isEmpty }) {
            pinDigits[lastFilledIndex] = ""
        }
    }
    
    func handleKeyInput(_ keyInput: KeyInput) {
        switch keyInput {
        case .digit(let digit):
            addDigit(digit)
            
            
            if pinDigits.joined().count == maxDigits {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    handleSubmit()
                }
            }
        case .backspace:
            removeDigit()
        case .returnKey:
            handleSubmit()
        case .escape:
            onDismiss()
        }
    }
    
    func handleSubmit() {
        let pin = pinDigits.joined()
        if pin.count == maxDigits {
            print("PIN entered: \(pin)")
            onPinSubmitted(pin)
        }
    }
}
