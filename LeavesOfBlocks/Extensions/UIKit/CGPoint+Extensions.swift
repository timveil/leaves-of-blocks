import CoreGraphics

extension CGPoint {
    
    /// Returns the distance to another point
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(x - point.x, 2) + pow(y - point.y, 2))
    }
    
    /// Returns the midpoint between this point and another
    func midpoint(to point: CGPoint) -> CGPoint {
        return CGPoint(
            x: (x + point.x) / 2,
            y: (y + point.y) / 2
        )
    }
    
    /// Returns true if the point is within a given rectangle
    func isInside(_ rect: CGRect) -> Bool {
        return rect.contains(self)
    }
}