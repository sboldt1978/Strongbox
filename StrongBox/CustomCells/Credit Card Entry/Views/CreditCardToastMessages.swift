import Foundation

class CreditCardToastMessages {
    
    public class func showSlim(title: String) {
        showSlim(title: title, delay: 1.5)
    }
    
    public class func showSlim(title: String, delay: TimeInterval) {
        #if !IS_APP_EXTENSION
        
        DispatchQueue.main.async {
            StrongboxToastMessages.showSlim(title: title, delay: delay)
        }
        #else
        
        print("Toast (Extension): \(title)")
        #endif
    }
    
    public class func showInfo(title: String, body: String) {
        #if !IS_APP_EXTENSION
        
        DispatchQueue.main.async {
            StrongboxToastMessages.showInfo(title: title, body: body)
        }
        #else
        
        print("Toast (Extension): \(title) - \(body)")
        #endif
    }
    
    public class func showWarning(title: String, body: String) {
        #if !IS_APP_EXTENSION
        
        DispatchQueue.main.async {
            StrongboxToastMessages.showWarning(title: title, body: body)
        }
        #else
        
        print("Toast (Extension): WARNING - \(title) - \(body)")
        #endif
    }
    
    public class func showError(title: String, body: String) {
        #if !IS_APP_EXTENSION
        
        DispatchQueue.main.async {
            StrongboxToastMessages.showError(title: title, body: body)
        }
        #else
        
        print("Toast (Extension): ERROR - \(title) - \(body)")
        #endif
    }
    
    public class func hideAll() {
        #if !IS_APP_EXTENSION
        
        DispatchQueue.main.async {
            StrongboxToastMessages.hideAll()
        }
        #else
        
        #endif
    }
} 
