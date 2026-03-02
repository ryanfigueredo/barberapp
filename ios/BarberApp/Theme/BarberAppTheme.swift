// BarberApp — Identidade visual (igual ao dashboard web)
// Luxury Barbershop / Noir Premium: #0A0A0A (bg) | #F5C518 (gold) | #1A1A1A (card)

import UIKit

enum BarberAppTheme {
    static let background = UIColor(red: 10/255, green: 10/255, blue: 10/255, alpha: 1)      // #0A0A0A
    static let card = UIColor(red: 26/255, green: 26/255, blue: 26/255, alpha: 1)             // #1A1A1A
    static let gold = UIColor(red: 245/255, green: 197/255, blue: 24/255, alpha: 1)          // #F5C518
    static let goldDim = UIColor(red: 245/255, green: 197/255, blue: 24/255, alpha: 0.2)
    static let textPrimary = UIColor.white
    static let textSecondary = UIColor.white.withAlphaComponent(0.7)
    static let textTertiary = UIColor.white.withAlphaComponent(0.5)
    static let border = UIColor.white.withAlphaComponent(0.08)
}
