import SwiftUI

struct CreditCardAdditionalDetailsSection: View {
    @ObservedObject var viewModel: CreditCardEditorViewModel
    let isEditing: Bool
    let focusedField: CreditCardFocusBinding
    let onCopy: (String, String) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            CreditCardFormRow(icon: Image(systemName: "lock.fill"), title: "PIN", interactable: isEditing) {
                CreditCardFormSecureInputView("1234", text: $viewModel.creditCardData.pin, isSecured: $viewModel.creditCardData.pinConcealed)
                    .keyboardType(.numberPad)
                    .focused(focusedField, equals: .pin)
                    .onChange(of: viewModel.creditCardData.pin) { _ in
                        viewModel.markAsChanged()
                    }
            } trailingContent: {
                Button {
                    viewModel.togglePinConcealed()
                } label: {
                    Image(systemName: viewModel.creditCardData.pinConcealed ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
                .frame(width: 25, height: 25, alignment: .center)
                .buttonStyle(.plain)
            }
            .tappable(isTappable: !isEditing) {
                onCopy(viewModel.creditCardData.pin, "PIN Copied")
            }
            
            CreditCardFormRow(icon: Image(systemName: "dollarsign.circle.fill"), title: "Credit Limit", interactable: isEditing) {
                TextField("10,000", text: $viewModel.creditCardData.creditLimit)
                    .keyboardType(.numberPad)
                    .focused(focusedField, equals: .creditLimit)
                    .onChange(of: viewModel.creditCardData.creditLimit) { newValue in
                        let formatted = newValue.formattedAsMoney()
                        if formatted != newValue {
                            viewModel.creditCardData.creditLimit = formatted
                        }
                        viewModel.markAsChanged()
                    }
            }
            .tappable(isTappable: !isEditing) {
                onCopy(viewModel.creditCardData.creditLimit, "Credit Limit Copied")
            }
            
            CreditCardFormRow(icon: Image(systemName: "banknote.fill"), title: "Cash Withdrawal Limit", interactable: isEditing) {
                TextField("10,000", text: $viewModel.creditCardData.cashWithdrawalLimit)
                    .keyboardType(.numberPad)
                    .onChange(of: viewModel.creditCardData.cashWithdrawalLimit) { newValue in
                        let formatted = newValue.formattedAsMoney()
                        if formatted != newValue {
                            viewModel.creditCardData.cashWithdrawalLimit = formatted
                        }
                        viewModel.markAsChanged()
                    }
            }
            .tappable(isTappable: !isEditing) {
                onCopy(viewModel.creditCardData.cashWithdrawalLimit, "Cash Withdrawal Limit Copied")
            }
            
            CreditCardFormRow(icon: Image(systemName: "percent"), title: "Interest Rate", interactable: isEditing) {
                TextField("Interest Rate", text: $viewModel.creditCardData.interestRate)
                    .keyboardType(.decimalPad)
                    .onChange(of: viewModel.creditCardData.interestRate) { _ in
                        viewModel.markAsChanged()
                    }
            }
            .tappable(isTappable: !isEditing) {
                onCopy(viewModel.creditCardData.interestRate, "Interest Rate Copied")
            }
            
            CreditCardFormRow(icon: Image(systemName: "number.circle.fill"), title: "Issue Number", interactable: isEditing) {
                TextField("Issue Number", text: $viewModel.creditCardData.issueNumber)
                    .onChange(of: viewModel.creditCardData.issueNumber) { _ in
                        viewModel.markAsChanged()
                    }
            }
            .tappable(isTappable: !isEditing) {
                onCopy(viewModel.creditCardData.issueNumber, "Issue Number Copied")
            }
        }
    }
}
