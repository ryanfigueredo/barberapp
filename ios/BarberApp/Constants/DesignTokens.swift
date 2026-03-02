// BarberApp — Design Tokens (Dark luxury barbershop)
// Ícones: SF Symbols nativos da Apple

import UIKit

enum BarberDesign {
    static let gold = UIColor(red: 0.96, green: 0.77, blue: 0.09, alpha: 1)
    static let goldDim = UIColor(red: 0.96, green: 0.77, blue: 0.09, alpha: 0.3)
    static let background = UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 1)   // #0A0A0A
    static let surface = UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1)      // #1A1A1A
    static let surfaceElevated = UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
    static let textPrimary = UIColor.white
    static let textSecondary = UIColor(white: 0.55, alpha: 1)
    static let textMuted = UIColor(white: 0.35, alpha: 1)
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
