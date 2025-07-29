import Foundation

extension Double {
    
    /// Rounds to a specified number of decimal places
    func rounded(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    /// Converts seconds to milliseconds
    var milliseconds: Int {
        return Int(self * 1000)
    }
}