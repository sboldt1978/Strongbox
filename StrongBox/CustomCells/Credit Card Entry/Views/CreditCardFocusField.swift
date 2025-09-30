import SwiftUI

enum CreditCardFocusField {
    case name
    case cardholderName
    case number
    case verificationNumber
    case pin
    case creditLimit
}


typealias CreditCardFocusBinding = FocusState<CreditCardFocusField?>.Binding 