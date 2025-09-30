import SwiftUI

struct CreditCardFormSecureInputView: View {
    
    @Binding private var text: String
    @Binding private var isSecured: Bool
    private let isEditable: Bool
    private let title: String
    
    init(_ title: String, isEditable: Bool = true, text: Binding<String>, isSecured: Binding<Bool>) {
        self._text = text
        self._isSecured = isSecured
        self.isEditable = isEditable
        self.title = title
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            Group {
                if isSecured {
                    SecureField(title, text: $text)
                        .frame(height: 24)
                } else {
                    TextField(title, text: $text)
                        .frame(height: 24)
                }
            }
            .allowsHitTesting(isEditable)
        }
    }
}
