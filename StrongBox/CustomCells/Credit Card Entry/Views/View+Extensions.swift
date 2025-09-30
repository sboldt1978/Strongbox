import SwiftUI

extension View {
    @ViewBuilder
    func `if`<Content: View>(
        _ conditional: Bool,
        @ViewBuilder _ content: (Self) -> Content
    ) -> some View {
        if conditional {
            content(self)
        } else {
            self
        }
    }
    
    func modify<Content: View>(
        @ViewBuilder _ transform: (Self) -> Content
    ) -> some View {
        transform(self)
    }
}
