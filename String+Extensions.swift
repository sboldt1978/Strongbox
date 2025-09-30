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
        guard !self.isEmpty else { return "" }
        
        
        let digits = self.filter(\.isWholeNumber)
        guard !digits.isEmpty else { return "" }
        
        
        guard let number = Int(digits) else { return digits }
        
        
        let formatter = NumberFormatter()
        formatter.locale = Locale.current
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = true
        
        
        let defaultSeparator = formatter.groupingSeparator ?? ","
        
        
        if defaultSeparator.trimmingCharacters(in: .whitespaces).isEmpty {
            formatter.groupingSeparator = ","
        }
        
        return formatter.string(from: NSNumber(value: number)) ?? digits
    }
    
    
    func formattedAsMoneyWithCommas() -> String {
        guard !self.isEmpty else { return "" }
        
        
        let digits = self.filter(\.isWholeNumber)
        guard !digits.isEmpty else { return "" }
        
        
        guard let number = Int(digits) else { return digits }
        
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "en_US")
        formatter.usesGroupingSeparator = true
        
        return formatter.string(from: NSNumber(value: number)) ?? digits
    }
}
