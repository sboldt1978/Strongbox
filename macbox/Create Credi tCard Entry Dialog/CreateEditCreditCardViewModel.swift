import Foundation
import Cocoa

final class CreateEditCreditCardViewModel: ObservableObject {
    
    @Published var title: String = "Credit Card"
    @Published var cardholderName: String = ""
    @Published var cardNumber: String = ""
    @Published var cvv: String = ""
    @Published var pin: String = ""
    @Published var creditLimit: String = ""
    @Published var cashWithdrawalLimit: String = ""
    @Published var interestRate: String = ""
    @Published var issueNumber: String = ""
    @Published var cardType: String = "Visa"
    @Published var notes: String = ""
    
    @Published var expiryDate: Date?
    @Published var validFromDate: Date?
    
    @Published var icon: NodeIcon
    @Published var iconExplicitlyChanged: Bool = false
    
    @Published var customFields: [(key: String, value: String, protected: Bool)] = []
    
    var database: ViewModel
    var model: EntryViewModel?
    private var initialNodeId: UUID?
    
    init(database: ViewModel, initialNodeId: UUID? = nil) {
        self.database = database
        self.initialNodeId = initialNodeId
        self.icon = Self.getDefaultCreditCardIcon()
        
        if initialNodeId == nil {
            self.iconExplicitlyChanged = true
        }
        
        loadModel()
    }
    
    private func loadModel() {
        if let nodeId = initialNodeId,
           let existingNode = database.getItemBy(nodeId) {
            guard let dbModel = database.commonModel else {
                swlog("🔴 Could not load common model!")
                return
            }
            model = EntryViewModel.fromNode(existingNode, model: dbModel)
            loadFromModel()
        } else {
            createNewModel()
        }
    }
    
    private func createNewModel() {
        guard let dbModel = database.commonModel else {
            swlog("🔴 Could not load common model!")
            return
        }
        
        let node = Node(asRecord: title, parent: database.rootGroup)
        node.icon = icon
        model = EntryViewModel.fromNode(node, model: dbModel)
        
        model?.parentGroupUuid = database.rootGroup.uuid
    }
    
    private func loadFromModel() {
        guard let model = model else { return }
        
        title = model.title
        cardholderName = model.username
        cardNumber = model.password
        notes = model.notes
        icon = model.icon ?? Self.getDefaultCreditCardIcon()
        expiryDate = model.expires
        
        loadCustomFieldsFromModel()
    }
    
    private func loadCustomFieldsFromModel() {
        guard let model = model else { return }
        
        customFields.removeAll()
        
        for field in model.customFieldsFiltered {
            switch field.key {
            case "CVV":
                cvv = field.value
            case "PIN":
                pin = field.value
            case "Credit Limit":
                creditLimit = field.value
            case "Cash Withdrawal Limit":
                cashWithdrawalLimit = field.value
            case "Interest Rate":
                interestRate = field.value
            case "Issue Number":
                issueNumber = field.value
            case "Card Type":
                cardType = field.value
            case "Valid From":
                validFromDate = parseDate(from: field.value)
            default:
                customFields.append((key: field.key, value: field.value, protected: field.protected))
            }
        }
    }
    
    func updateModel() {
        guard let model = model else { return }
        
        model.title = title.isEmpty ? "Credit Card" : title
        model.username = cardholderName
        model.password = cardNumber
        model.notes = notes
        model.expires = expiryDate
        
        if initialNodeId == nil || iconExplicitlyChanged {
            model.icon = icon
        }
        
        updateCustomFieldsInModel()
    }
    
    private func updateCustomFieldsInModel() {
        guard let model = model else { return }
        
        let fieldsToRemove = ["CVV", "PIN", "Credit Limit", "Cash Withdrawal Limit", 
                             "Interest Rate", "Issue Number", "Card Type", "Valid From"]
        
        for fieldKey in fieldsToRemove {
            if let index = model.customFieldsFiltered.enumerated().first(where: { $0.element.key == fieldKey })?.offset {
                model.removeCustomField(at: UInt(index))
            }
        }
        
        addCustomFieldIfNotEmpty("CVV", value: cvv, protected: true)
        addCustomFieldIfNotEmpty("PIN", value: pin, protected: true)
        addCustomFieldIfNotEmpty("Credit Limit", value: creditLimit, protected: false)
        addCustomFieldIfNotEmpty("Cash Withdrawal Limit", value: cashWithdrawalLimit, protected: false)
        addCustomFieldIfNotEmpty("Interest Rate", value: interestRate, protected: false)
        addCustomFieldIfNotEmpty("Issue Number", value: issueNumber, protected: false)
        
        if cardType != "Visa" {
            addCustomFieldIfNotEmpty("Card Type", value: cardType, protected: false)
        }
        
        if let validFromDate = validFromDate {
            let dateString = formatDate(validFromDate)
            addCustomFieldIfNotEmpty("Valid From", value: dateString, protected: false)
        }
        
        for customField in customFields {
            addCustomFieldIfNotEmpty(customField.key, value: customField.value, protected: customField.protected)
        }
    }
    
    private func addCustomFieldIfNotEmpty(_ key: String, value: String, protected: Bool) {
        guard !value.isEmpty, let model = model else { return }
        
        let field = CustomFieldViewModel.customField(withKey: key, value: value, protected: protected)
        model.addCustomField(field)
    }
    
    func save() -> UUID? {
        updateModel()
        
        guard let model = model else {
            swlog("🔴 Model not available for saving")
            return nil
        }
        
        if let nodeId = initialNodeId {
            if database.applyEditsAndMoves(model, toNode: nodeId) {
                return nodeId
            }
        } else {
            guard let dbModel = database.commonModel else {
                swlog("🔴 Could not load common model!")
                return nil
            }
            
            let parentGroup: Node
            if let parentGroupUuid = model.parentGroupUuid,
               let foundParent = database.getItemBy(parentGroupUuid) {
                parentGroup = foundParent
            } else {
                parentGroup = database.rootGroup
            }
            
            let node = Node(asRecord: model.title, parent: parentGroup)
            model.apply(to: node, model: dbModel, legacySupplementaryTotp: false, addOtpAuthUrl: true)
            
            node.icon = icon
            
            if database.addChildren([node], parent: parentGroup) {
                database.nextGenSelectedItems = [node.uuid]
                
                initialNodeId = node.uuid
                
                if Settings.sharedInstance().autoSave {
                    DispatchQueue.main.async { [weak self] in
                        self?.database.document?.save(nil)
                    }
                }
                
                return node.uuid
            }
        }
        
        return nil
    }
    
    func addCustomField(key: String, value: String, protected: Bool) {
        customFields.append((key: key, value: value, protected: protected))
    }
    
    func removeCustomField(at index: Int) {
        guard index < customFields.count else { return }
        customFields.remove(at: index)
    }
    
    func updateCustomField(at index: Int, key: String, value: String, protected: Bool) {
        guard index < customFields.count else { return }
        customFields[index] = (key: key, value: value, protected: protected)
    }
    
    func setValidFromDate() {
        validFromDate = Date()
    }
    
    func setExpiryDate() {
        let now = Date()
        expiryDate = now.addMonth(n: 3)
    }
    
    func clearValidFromDate() {
        validFromDate = nil
    }
    
    func clearExpiryDate() {
        expiryDate = nil
    }
    
    func setIcon(_ newIcon: NodeIcon?) {
        if let newIcon = newIcon {
            icon = newIcon
            iconExplicitlyChanged = true
        }
    }
    
    var parentGroupUuid: UUID? {
        return model?.parentGroupUuid
    }
    
    func setParentGroup(_ groupUuid: UUID) {
        model?.parentGroupUuid = groupUuid
    }
    
    var isValid: Bool {
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var hasChanges: Bool {
        return true
    }
    
    private func parseDate(from string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.date(from: string)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    static func getDefaultCreditCardIcon() -> NodeIcon {
        return NodeIcon.withPreset(9)
    }
    
    var customFieldSuggestions: Set<String> {
        return Set([
            "Bank Name",
            "Account Number",
            "Customer Service",
            "Credit Limit",
            "Interest Rate",
            "Annual Fee",
            "Reward Program",
            "Statement Date",
            "Payment Due Date",
            "Minimum Payment"
        ])
    }
    
    var availableCardTypes: [String] {
          return [
            "Visa",
            "MasterCard", 
            "American Express",
            "Discover",
            "Diners Club",
            "JCB",
            "Other"
        ]
    }
    
    var favourite: Bool {
        get { model?.favourite ?? false }
        set { model?.favourite = newValue }
    }
} 