import SwiftUI

struct AddCustomFieldView: View {
    @Binding var key: String
    @Binding var value: String
    @Binding var isConceablable: Bool
    
    let isEditing: Bool
    let onSave: (Bool) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $key)
                    TextField("Value", text: $value)
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle(isOn: $isConceablable) {
                            Text("Concealable")
                        }
                        Text("This means this field looks and behaves like a password field. You can conceal and reveal it in the UI.")
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Custom Field" : "Add Custom Field")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(isConceablable)
                    }
                    .disabled(key.isEmpty)
                }
            }
        }
    }
}
