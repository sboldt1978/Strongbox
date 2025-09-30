enum CardType: String, CaseIterable {
    case visa = "Visa"
    case mastercard = "MasterCard"
    case americanExpress = "American Express"
    case discover = "Discover"
    case dinersClub = "Diners Club"
    case jcb = "JCB"
    case other = "Other"
}

struct CardTypingDetection {
    let type: CardType
    
    let isConfirmed: Bool
    
    
    let moreDigitsNeededToConfirm: Int?
}

struct CardDetection {
    
    
    static func detectCardType(_ raw: String) -> CardTypingDetection {
        let digits = raw.filter(\.isNumber)
        let c = digits.count
        
        
        func p(_ n: Int) -> Int {
            guard c >= n, let v = Int(digits.prefix(n)) else { return -1 }
            return v
        }
        
        let p1 = p(1), p2 = p(2), p3 = p(3), p4 = p(4), p6 = p(6)
        
        
        if (622126...622925).contains(p6) { 
            return .init(type: .discover, isConfirmed: true, moreDigitsNeededToConfirm: 0)
        }
        if (2221...2720).contains(p4) {     
            return .init(type: .mastercard, isConfirmed: true, moreDigitsNeededToConfirm: 0)
        }
        if p4 == 6011 {                      
            return .init(type: .discover, isConfirmed: true, moreDigitsNeededToConfirm: 0)
        }
        if (3528...3589).contains(p4) {      
            return .init(type: .jcb, isConfirmed: true, moreDigitsNeededToConfirm: 0)
        }
        if (300...305).contains(p3) {        
            return .init(type: .dinersClub, isConfirmed: true, moreDigitsNeededToConfirm: 0)
        }
        if p4 == 3095 {                      
            return .init(type: .dinersClub, isConfirmed: true, moreDigitsNeededToConfirm: 0)
        }
        if (644...649).contains(p3) {        
            return .init(type: .discover, isConfirmed: true, moreDigitsNeededToConfirm: 0)
        }
        if (51...55).contains(p2) {          
            return .init(type: .mastercard, isConfirmed: true, moreDigitsNeededToConfirm: 0)
        }
        if p2 == 65 {                        
            return .init(type: .discover, isConfirmed: true, moreDigitsNeededToConfirm: 0)
        }
        if p2 == 34 || p2 == 37 {            
            return .init(type: .americanExpress, isConfirmed: true, moreDigitsNeededToConfirm: 0)
        }
        if p2 == 36 || (38...39).contains(p2) { 
            return .init(type: .dinersClub, isConfirmed: true, moreDigitsNeededToConfirm: 0)
        }
        if p1 == 4 {                         
            return .init(type: .visa, isConfirmed: true, moreDigitsNeededToConfirm: 0)
        }
        
        
        
        
        
        if c >= 3, p3 == 622 {
            return .init(type: .discover, isConfirmed: false, moreDigitsNeededToConfirm: max(0, 6 - c))
        }
        if c == 2, p2 == 62 { 
            return .init(type: .discover, isConfirmed: false, moreDigitsNeededToConfirm: 6 - c)
        }
        
        
        if c >= 2, (22...27).contains(p2) {
            return .init(type: .mastercard, isConfirmed: false, moreDigitsNeededToConfirm: max(0, 4 - c))
        }
        
        
        if c >= 2, p2 == 35 {
            return .init(type: .jcb, isConfirmed: false, moreDigitsNeededToConfirm: max(0, 4 - c))
        }
        
        
        if c >= 2, p2 == 30 {
            let needed = (c >= 3) ? 4 : 3
            return .init(type: .dinersClub, isConfirmed: false, moreDigitsNeededToConfirm: needed - c)
        }
        
        
        return .init(type: .other, isConfirmed: false, moreDigitsNeededToConfirm: nil)
    }
}
