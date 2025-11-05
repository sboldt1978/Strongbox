import WidgetKit
import SwiftUI

@main
struct StrongboxWidgetBundle: WidgetBundle {
    var body: some Widget {
        StrongboxWidget()
        StrongboxWidgetControl()
    }
}
