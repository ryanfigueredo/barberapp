// BarberApp — Models

import Foundation
import UIKit

struct Appointment: Codable {
    let id: String
    let customerName: String
    let customerPhone: String
    let appointmentDate: String
    let status: AppointmentStatus
    let barber: BarberInfo
    let service: ServiceInfo?
    let customerNotes: String?
    let barberNotes: String?
    let origin: String

    enum CodingKeys: String, CodingKey {
        case id, status, origin
        case customerName = "customer_name"
        case customerPhone = "customer_phone"
        case appointmentDate = "appointment_date"
        case barber, service
        case customerNotes = "customer_notes"
        case barberNotes = "barber_notes"
    }
}

enum AppointmentStatus: String, Codable {
    case pending
    case confirmed
    case inProgress = "in_progress"
    case completed
    case cancelled
    case noShow = "no_show"

    var displayName: String {
        switch self {
        case .pending: return "Pendente"
        case .confirmed: return "Confirmado"
        case .inProgress: return "Em andamento"
        case .completed: return "Concluído"
        case .cancelled: return "Cancelado"
        case .noShow: return "Não compareceu"
        }
    }

    var color: UIColor {
        switch self {
        case .pending: return .systemOrange
        case .confirmed: return .systemBlue
        case .inProgress: return .systemGreen
        case .completed: return .systemGray
        case .cancelled: return .systemRed
        case .noShow: return .systemRed.withAlphaComponent(0.5)
        }
    }
}

struct BarberInfo: Codable {
    let id: String
    let name: String
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case avatarUrl = "avatar_url"
    }
}

struct ServiceInfo: Codable {
    let id: String
    let name: String
    let price: Double
    let durationMinutes: Int

    enum CodingKeys: String, CodingKey {
        case id, name, price
        case durationMinutes = "duration_minutes"
    }
}
