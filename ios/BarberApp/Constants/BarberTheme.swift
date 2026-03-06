//
//  BarberTheme.swift
//  BarberApp
//
//  Design tokens — dark luxury barbershop. Alinhado a DesignSystem (#141416, #D9AE59).
//

import UIKit

enum BarberTheme {
    // Cores
    static let gold        = UIColor(red: 217/255, green: 174/255, blue: 89/255, alpha: 1.0)   // #D9AE59
    static let goldDim     = UIColor(red: 217/255, green: 174/255, blue: 89/255, alpha: 0.25)
    static let goldGlow    = UIColor(red: 217/255, green: 174/255, blue: 89/255, alpha: 0.08)
    static let bg          = UIColor(red: 20/255, green: 20/255, blue: 22/255, alpha: 1.0)     // #141416
    static let surface     = UIColor(white: 1, alpha: 0.06)
    static let surfaceHigh = UIColor(white: 1, alpha: 0.08)
    static let border      = UIColor(white: 1, alpha: 0.07)
    static let textPrimary = UIColor.white
    static let textSecond  = UIColor(white: 1, alpha: 0.45)
    static let textMuted   = UIColor(white: 1, alpha: 0.35)
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
