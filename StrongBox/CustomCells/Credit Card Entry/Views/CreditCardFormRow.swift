import SwiftUI

struct CreditCardFormRow<Content: View, Action: View>: View {
    private var icon: Image?
    private var title: String
    private var interactable: Bool
    private var content: () -> Content
    private var trailingContent: (() -> Action)?
    
    init(
        icon: Image?,
        title: String,
        interactable: Bool,
        @ViewBuilder content: @escaping () -> Content
    ) where Action == EmptyView {
        self.icon = icon
        self.title = title
        self.interactable = interactable
        self.content = content
        self.trailingContent = nil
    }
    
    init(
        icon: Image?,
        title: String,
        interactable: Bool,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder trailingContent: @escaping () -> Action
    ) {
        self.icon = icon
        self.title = title
        self.interactable = interactable
        self.content = content
        self.trailingContent = trailingContent
    }
    
    var body: some View {
        HStack(alignment: .contentAlignment, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 4) {
                    if let icon {
                        icon
                            .symbolVariant(.fill)
                    }
                    Text(title)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                
                content()
                    .font(.callout)
                    .alignmentGuide(.contentAlignment) { $0[VerticalAlignment.center] }
            }
            .allowsHitTesting(interactable)
            
            if let trailingContent = trailingContent {
                trailingContent()
                    .alignmentGuide(.contentAlignment) { $0[VerticalAlignment.center] }
            }
        }
    }
}

extension VerticalAlignment {
    static let contentAlignment = VerticalAlignment(ContentAlignment.self)
}

private enum ContentAlignment: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
        context[VerticalAlignment.center]
    }
}
