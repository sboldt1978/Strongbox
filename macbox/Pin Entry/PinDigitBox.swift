import SwiftUI

struct PinDigitBox: View {
    @Binding var digit: String
    let isActive: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isActive ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: 2)
                .frame(width: 50, height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                .animation(.snappy, value: isActive)
            
            if !digit.isEmpty {
                Text("●")
                    .font(.title)
                    .foregroundColor(.primary)
                    .animation(.snappy, value: !digit.isEmpty)
            }
        }
    }
}
