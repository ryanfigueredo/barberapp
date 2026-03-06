//
//  DesignSystem.swift
//  BarberApp
//
//  Fonte da verdade: background #141416, accent #D9AE59, cards 5–8% branco, radius 14.
//

import SwiftUI
import UIKit

// MARK: - Design system (SwiftUI)
enum BarberDesignSystem {
    /// Background principal — quase preto
    static let background = Color(red: 20/255, green: 20/255, blue: 22/255)   // #141416
    /// Accent / gold
    static let gold = Color(red: 217/255, green: 174/255, blue: 89/255)      // #D9AE59
    static let goldLight = Color(red: 0.95, green: 0.82, blue: 0.55)
    static let goldOpacity12 = gold.opacity(0.12)
    static let goldOpacity25 = gold.opacity(0.25)
    static let goldOpacity35 = gold.opacity(0.35)
    static let goldOpacity18 = gold.opacity(0.18)
    static let goldOpacity10 = gold.opacity(0.10)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.45)
    static let textMuted = Color.white.opacity(0.35)

    /// Cards: branco 5–8%
    static let card = Color.white.opacity(0.05)
    static let cardHighlight = Color.white.opacity(0.08)
    static let border = Color.white.opacity(0.07)
    static let borderGold = gold.opacity(0.5)

    static let cornerRadius: CGFloat = 14
    static let cornerRadiusSmall: CGFloat = 10

    // Tipografia
    static func titleLarge() -> Font { .system(size: 32, weight: .black, design: .default) }
    static func titleMedium() -> Font { .system(size: 28, weight: .black, design: .default) }
    static func titleSmall() -> Font { .system(size: 18, weight: .bold, design: .default) }
    static func body() -> Font { .system(size: 15, weight: .regular, design: .default) }
    static func bodySmall() -> Font { .system(size: 14, weight: .regular, design: .default) }
    static func caption() -> Font { .system(size: 12, weight: .regular, design: .default) }
    static func overline() -> Font { .system(size: 11, weight: .semibold, design: .default) }
    static let trackingHigh: CGFloat = 10
}

// MARK: - UIKit (BarberTheme alignment)
extension UIColor {
    static var barberBackground: UIColor { BarberDesignSystemUIKit.background }
    static var barberGold: UIColor { BarberDesignSystemUIKit.gold }
    static var barberSurface: UIColor { BarberDesignSystemUIKit.surface }
    static var barberTextPrimary: UIColor { BarberDesignSystemUIKit.textPrimary }
    static var barberTextSecondary: UIColor { BarberDesignSystemUIKit.textSecondary }
    static var barberTextMuted: UIColor { BarberDesignSystemUIKit.textMuted }
    static var barberBorder: UIColor { BarberDesignSystemUIKit.border }
}

enum BarberDesignSystemUIKit {
    static let background = UIColor(red: 20/255, green: 20/255, blue: 22/255, alpha: 1)   // #141416
    static let gold = UIColor(red: 217/255, green: 174/255, blue: 89/255, alpha: 1)      // #D9AE59
    static let goldDim = UIColor(red: 217/255, green: 174/255, blue: 89/255, alpha: 0.25)
    static let surface = UIColor(white: 1, alpha: 0.06)
    static let surfaceHigh = UIColor(white: 1, alpha: 0.08)
    static let textPrimary = UIColor.white
    static let textSecondary = UIColor(white: 1, alpha: 0.45)
    static let textMuted = UIColor(white: 1, alpha: 0.35)
    static let border = UIColor(white: 1, alpha: 0.07)
    static let success = UIColor(red: 0.20, green: 0.84, blue: 0.40, alpha: 1)
    static let warning = UIColor(red: 0.96, green: 0.62, blue: 0.10, alpha: 1)
    static let danger = UIColor(red: 0.94, green: 0.27, blue: 0.27, alpha: 1)
    static let blue = UIColor(red: 0.23, green: 0.51, blue: 0.96, alpha: 1)
    static let tabBarHeight: CGFloat = 68
    static let tabBarRadius: CGFloat = 28
    static let tabBarSideMargin: CGFloat = 18
    static let tabBarBottomOffset: CGFloat = 14
}
