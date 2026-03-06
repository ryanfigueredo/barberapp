// BarberApp — Design Tokens (Dark luxury #141416 / #D9AE59)

import UIKit

enum BarberDesign {
    static let gold = UIColor(red: 217/255, green: 174/255, blue: 89/255, alpha: 1)
    static let goldDim = UIColor(red: 217/255, green: 174/255, blue: 89/255, alpha: 0.3)
    static let background = UIColor(red: 20/255, green: 20/255, blue: 22/255, alpha: 1)   // #141416
    static let surface = UIColor(white: 1, alpha: 0.06)
    static let surfaceElevated = UIColor(white: 1, alpha: 0.08)
    static let textPrimary = UIColor.white
    static let textSecondary = UIColor(white: 1, alpha: 0.45)
    static let textMuted = UIColor(white: 1, alpha: 0.35)
    static let success = UIColor(red: 0.2, green: 0.85, blue: 0.4, alpha: 1)
    static let warning = UIColor(red: 0.96, green: 0.6, blue: 0.1, alpha: 1)
    static let error = UIColor(red: 0.95, green: 0.27, blue: 0.27, alpha: 1)
    static let tabBarHeight: CGFloat = 64
    static let tabBarRadius: CGFloat = 28
    static let tabBarMargin: CGFloat = 20
    static let tabBarBottomOffset: CGFloat = 12

    /// SF Symbols para as tabs (nativos Apple)
    enum TabIcon {
        static let calendar = "calendar"
        static let appointments = "list.bullet.clipboard"
        static let barbers = "person.2.fill"
        static let services = "scissors"
        static let messages = "bubble.left.and.bubble.right.fill"
    }
}
