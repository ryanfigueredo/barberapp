//
//  AppointmentNotificationService.swift
//  BarberApp
//
//  Notificações locais quando estiver chegando o horário do agendamento.
//

import Foundation
import UserNotifications

/// Agenda notificações locais para agendamentos futuros (ex.: 15 min, 30 min, 1h antes).
final class AppointmentNotificationService {

    static let shared = AppointmentNotificationService()

    /// Prefixo dos identifiers para poder cancelar em lote
    private let identifierPrefix = "barber-appt"

    /// Intervalos antes do horário para notificar (em minutos)
    private let reminderMinutes: [Int] = [15, 30, 60]

    private let isoFormatter = ISO8601DateFormatter()
    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "pt_BR")
        return f
    }()

    private init() {}

    // MARK: - Permissão

    /// Chame no launch do app para pedir permissão de notificações.
    func requestPermission(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async { completion?(granted) }
        }
    }

    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus) }
        }
    }

    // MARK: - Agendar / Cancelar

    /// Agenda notificações para os agendamentos passados (apenas futuros, pending/confirmed).
    /// Deve ser chamado sempre que a lista de appointments for carregada (ex.: após fetch).
    func scheduleForAppointments(_ appointments: [Appointment]) {
        cancelAllAppointmentNotifications()

        let now = Date()
        let cal = Calendar.current

        for appt in appointments {
            guard appt.status == .pending || appt.status == .confirmed,
                  let date = isoFormatter.date(from: appt.appointmentDate),
                  date > now else { continue }

            let title = "Agendamento em breve"
            let timeStr = timeFormatter.string(from: date)
            let body = "\(appt.customerName) às \(timeStr)\(appt.service.map { " · \($0.name)" } ?? "")"

            for minutes in reminderMinutes {
                guard let triggerDate = cal.date(byAdding: .minute, value: -minutes, to: date),
                      triggerDate > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = title
                content.body = body
                content.sound = .default

                let components = cal.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                let id = "\(identifierPrefix)-\(appt.id)-\(minutes)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request) { _ in }
            }
        }
    }

    /// Remove todas as notificações de agendamentos (para re-sincronizar depois).
    func cancelAllAppointmentNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            guard let prefix = self?.identifierPrefix else { return }
            let ids = requests.filter { $0.identifier.hasPrefix(prefix) }.map(\.identifier)
            guard !ids.isEmpty else { return }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }
}
