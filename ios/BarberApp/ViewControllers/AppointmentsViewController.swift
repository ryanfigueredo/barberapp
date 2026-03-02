//
//  AppointmentsViewController.swift
//  BarberApp
//
//  Lista de agendamentos do dia (ou próximos)
//

import UIKit

class AppointmentsViewController: UIViewController {

    private var appointments: [Appointment] = []
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let refreshControl = UIRefreshControl()
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "pt_BR")
        return f
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Agendamentos"
        view.backgroundColor = BarberAppTheme.background
        navigationController?.navigationBar.prefersLargeTitles = true
        setupTableView()
        loadAppointments()
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorColor = BarberAppTheme.border
        tableView.register(AppointmentRowCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)

        refreshControl.tintColor = BarberAppTheme.gold
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        emptyLabel.text = "Nenhum agendamento para hoje"
        emptyLabel.textColor = BarberAppTheme.textTertiary
        emptyLabel.font = .systemFont(ofSize: 16)
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func loadAppointments() {
        let today = dateFormatter.string(from: Date())
        Task {
            do {
                let res = try await ApiService.shared.getAppointments(date: today)
                await MainActor.run {
                    appointments = res.appointments
                    tableView.reloadData()
                    emptyLabel.isHidden = !appointments.isEmpty
                    refreshControl.endRefreshing()
                }
            } catch {
                await MainActor.run {
                    appointments = []
                    tableView.reloadData()
                    emptyLabel.isHidden = false
                    refreshControl.endRefreshing()
                }
            }
        }
    }

    @objc private func handleRefresh() {
        loadAppointments()
    }
}

extension AppointmentsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        appointments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! AppointmentRowCell
        cell.configure(with: appointments[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Célula de agendamento na lista
private final class AppointmentRowCell: UITableViewCell {
    private let timeLabel = UILabel()
    private let serviceLabel = UILabel()
    private let customerLabel = UILabel()
    private let barberLabel = UILabel()
    private let statusBadge = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        timeLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        timeLabel.textColor = BarberAppTheme.gold
        serviceLabel.font = .systemFont(ofSize: 15, weight: .medium)
        serviceLabel.textColor = BarberAppTheme.textPrimary
        customerLabel.font = .systemFont(ofSize: 13)
        customerLabel.textColor = BarberAppTheme.textSecondary
        barberLabel.font = .systemFont(ofSize: 12)
        barberLabel.textColor = BarberAppTheme.textTertiary
        statusBadge.font = .systemFont(ofSize: 11, weight: .medium)
        statusBadge.textAlignment = .center
        statusBadge.layer.cornerRadius = 6
        statusBadge.clipsToBounds = true

        let stack = UIStackView(arrangedSubviews: [timeLabel, serviceLabel, customerLabel, barberLabel, statusBadge])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ])
    }

    func configure(with a: Appointment) {
        let time = (ISO8601DateFormatter().date(from: a.appointmentDate)).map {
            DateFormatter.localizedString(from: $0, dateStyle: .none, timeStyle: .short)
        } ?? "-"
        timeLabel.text = time
        serviceLabel.text = a.service?.name ?? "Serviço"
        customerLabel.text = a.customerName
        barberLabel.text = "💈 \(a.barber.name)"
        statusBadge.text = " \(a.status.displayName) "
        statusBadge.backgroundColor = a.status.color.withAlphaComponent(0.3)
        statusBadge.textColor = a.status.color
    }
}
