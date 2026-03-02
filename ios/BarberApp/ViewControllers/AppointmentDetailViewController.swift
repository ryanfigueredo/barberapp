//
//  AppointmentDetailViewController.swift
//  BarberApp
//

import UIKit

class AppointmentDetailViewController: UIViewController {

    private let appointment: Appointment

    init(appointment: Appointment) {
        self.appointment = appointment
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BarberTheme.bg
        title = "Agendamento"

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        let timeStr: String = {
            guard let d = ISO8601DateFormatter().date(from: appointment.appointmentDate) else { return "-" }
            let fmt = DateFormatter()
            fmt.dateFormat = "HH:mm"
            return fmt.string(from: d)
        }()

        addRow(stack: stack, title: "Horário", value: timeStr)
        addRow(stack: stack, title: "Cliente", value: appointment.customerName)
        addRow(stack: stack, title: "Telefone", value: appointment.customerPhone)
        addRow(stack: stack, title: "Barbeiro", value: appointment.barber.name)
        addRow(stack: stack, title: "Serviço", value: appointment.service?.name ?? "-")
        addRow(stack: stack, title: "Status", value: BarberTheme.statusLabel(appointment.status.rawValue))

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    private func addRow(stack: UIStackView, title: String, value: String) {
        let lbl = UILabel()
        lbl.text = "\(title): \(value)"
        lbl.font = .systemFont(ofSize: 15)
        lbl.textColor = BarberTheme.textPrimary
        lbl.numberOfLines = 0
        stack.addArrangedSubview(lbl)
    }
}
