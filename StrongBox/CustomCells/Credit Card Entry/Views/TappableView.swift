import SwiftUI

struct TappableView: ViewModifier {
    let isTappable: Bool
    let onTap: () -> Void
    
    func body(content: Content) -> some View {
        content.if(isTappable) { view in
            view
                .contentShape(Rectangle())
                .onTapGesture(perform: onTap)
            }
    }
}

extension View {
    func tappable(isTappable: Bool, onTap: @escaping () -> Void) -> some View {
        modifier(TappableView(isTappable: isTappable, onTap: onTap))
    }
}
