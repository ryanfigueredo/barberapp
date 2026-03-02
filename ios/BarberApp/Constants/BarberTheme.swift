//
//  BarberTheme.swift
//  BarberApp
//
//  Design tokens — dark luxury barbershop. Use em TODO o app.
//

import UIKit

enum BarberTheme {
    // Cores
    static let gold        = UIColor(red: 0.96, green: 0.77, blue: 0.09, alpha: 1.0)  // #F5C518
    static let goldDim     = UIColor(red: 0.96, green: 0.77, blue: 0.09, alpha: 0.25)
    static let goldGlow    = UIColor(red: 0.96, green: 0.77, blue: 0.09, alpha: 0.08)
    static let bg          = UIColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 1.0)  // #0A0A0A
    static let surface     = UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.0)  // #1A1A1A
    static let surfaceHigh = UIColor(red: 0.16, green: 0.16, blue: 0.16, alpha: 1.0)  // #292929
    static let border      = UIColor(white: 1, alpha: 0.07)
    static let textPrimary = UIColor.white
    static let textSecond  = UIColor(white: 0.55, alpha: 1)
    static let textMuted   = UIColor(white: 0.32, alpha: 1)
    static let success     = UIColor(red: 0.20, green: 0.84, blue: 0.40, alpha: 1.0)
    static let warning     = UIColor(red: 0.96, green: 0.62, blue: 0.10, alpha: 1.0)
    static let danger      = UIColor(red: 0.94, green: 0.27, blue: 0.27, alpha: 1.0)
    static let blue        = UIColor(red: 0.23, green: 0.51, blue: 0.96, alpha: 1.0)

    // Status colors (por string da API)
    static func statusColor(_ status: String) -> UIColor {
        switch status {
        case "confirmed":   return blue
        case "pending":     return warning
        case "in_progress": return success
        case "completed":   return UIColor(white: 0.45, alpha: 1)
        case "cancelled":   return danger
        case "no_show":     return danger.withAlphaComponent(0.6)
        default:            return textSecond
        }
    }

    static func statusLabel(_ status: String) -> String {
        switch status {
        case "confirmed":   return "Confirmado"
        case "pending":     return "Pendente"
        case "in_progress": return "Em andamento"
        case "completed":   return "Concluído"
        case "cancelled":   return "Cancelado"
        case "no_show":     return "Não veio"
        default:            return status
        }
    }

    // Tab bar
    static let tabBarHeight:       CGFloat = 68
    static let tabBarRadius:       CGFloat = 28
    static let tabBarSideMargin:   CGFloat = 18
    static let tabBarBottomOffset: CGFloat = 14
}
