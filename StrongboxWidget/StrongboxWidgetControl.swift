import AppIntents
import SwiftUI
import WidgetKit

struct StrongboxWidgetControl: ControlWidget {
    static let kind: String = "com.markmcguill.strongbox.pro.watch.StrongboxWidget"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: Self.kind,
        ) {
            ControlWidgetButton(action: PerformAction()) {
                Label("2FA Quick Access", systemImage: "lock.shield")
            }
        }
        .displayName("2FA Quick Access")
        .description("Strongbox 2FA quick access.")
    }
}

struct PerformAction: AppIntent {
    static let title: LocalizedStringResource = "Open 2FAs"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
