import Foundation

extension String {
    func formattedAsExpiryDate() -> String {
        let digits = self.filter { $0.isNumber }
        let prefix = digits.prefix(4)
        switch prefix.count {
        case 0...1:
            return String(prefix)
        case 2:
            return "\(prefix.prefix(2))"
        case 3:
            return "\(prefix.prefix(2)) / \(prefix.suffix(1))"
        case 4:
            let mm = prefix.prefix(2)
            let yy = prefix.suffix(2)
            return "\(mm) / \(yy)"
        default:
            return "\(prefix.prefix(2)) / \(prefix.suffix(2))"
        }
    }
    
    func formattedAsCreditCardNumber() -> String {
        let digits = self.filter { $0.isNumber }
        let truncated = String(digits.prefix(16))
        let groups = stride(from: 0, to: truncated.count, by: 4).map {
            let start = truncated.index(truncated.startIndex, offsetBy: $0)
            let end = truncated.index(start, offsetBy: min(4, truncated.count - $0))
            return String(truncated[start..<end])
        }
        return groups.joined(separator: "-")
    }
    
    func formattedAsMoney() -> String {
        if self.isEmpty { return "" }
        let components = self.components(separatedBy: ".")
        let integerPart = components[0]
        let decimalPart = components.count > 1 ? components[1] : ""
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        formatter.groupingSize = 3
        
        if let number = Int(integerPart), let formatted = formatter.string(from: NSNumber(value: number)) {
            return decimalPart.isEmpty ? formatted : "\(formatted).\(decimalPart)"
        }
        return self
    }
}
