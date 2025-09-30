import SwiftUI

struct MultilineTextField: View {
    @Binding var text: String
    let placeholder: String
    var minHeight: CGFloat = 100
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
            }
            
            TextEditor(text: $text)
                .frame(minHeight: minHeight)
                .background(Color.clear)
        }
    }
}
