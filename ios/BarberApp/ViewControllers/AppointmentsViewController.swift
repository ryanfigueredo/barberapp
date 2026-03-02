//
//  AppointmentsViewController.swift
//  BarberApp
//
//  Lista de agendamentos com segmento (Hoje / Próximos 7 / Todos) e swipe actions
//

import UIKit

class AppointmentsViewController: UIViewController {

    private var appointments: [Appointment] = []
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let segmentControl = UISegmentedControl(items: ["Hoje", "Próximos 7 dias", "Todos"])
    private let refreshControl = UIRefreshControl()
    private var selectedFilter = 0

    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "pt_BR")
        return f
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Agendamentos"
        view.backgroundColor = BarberTheme.bg
        navigationController?.navigationBar.prefersLargeTitles = true
        setupSegment()
        setupTableView()
        loadAppointments()
    }

    private func setupSegment() {
        segmentControl.selectedSegmentIndex = 0
        segmentControl.backgroundColor = BarberTheme.surface
        segmentControl.selectedSegmentTintColor = BarberTheme.gold
        segmentControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        segmentControl.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
        segmentControl.addTarget(self, action: #selector(filterChanged), for: .valueChanged)

        let container = UIView()
        container.addSubview(segmentControl)
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            segmentControl.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            segmentControl.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8),
            segmentControl.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            segmentControl.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
        ])
        tableView.tableHeaderView = container
        container.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 52)
    }

    private func setupTableView() {
        tableView.backgroundColor = BarberTheme.bg
        tableView.separatorStyle = .none
        tableView.register(AppointmentRowCell.self, forCellReuseIdentifier: "row")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 88
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 90, right: 0)
        refreshControl.tintColor = BarberTheme.gold
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func loadAppointments() {
        let path: String
        switch selectedFilter {
        case 0:
            let today = dateFormatter.string(from: Date())
            path = "/api/app/appointments?date=\(today)"
        case 1:
            path = "/api/app/appointments?upcoming=true"
        default:
            path = "/api/app/appointments?upcoming=true"
        }

        ApiService.shared.fetch(path) { [weak self] (result: Result<AppointmentsResponse, Error>) in
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
                if case .success(let r) = result {
                    self?.appointments = r.appointments
                    self?.tableView.reloadData()
                }
            }
        }
    }

    @objc private func filterChanged() {
        selectedFilter = segmentControl.selectedSegmentIndex
        loadAppointments()
    }

    @objc private func handleRefresh() {
        loadAppointments()
    }

    private func updateStatus(_ id: String, status: String, at ip: IndexPath) {
        ApiService.shared.updateAppointmentStatus(id: id, status: status) { [weak self] _ in
            DispatchQueue.main.async {
                self?.loadAppointments()
            }
        }
    }
}

extension AppointmentsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tv: UITableView, numberOfRowsInSection s: Int) -> Int { appointments.count }

    func tableView(_ tv: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "row", for: ip) as! AppointmentRowCell
        cell.configure(with: appointments[ip.row])
        return cell
    }

    func tableView(_ tv: UITableView, didSelectRowAt ip: IndexPath) {
        tv.deselectRow(at: ip, animated: true)
        let vc = AppointmentDetailViewController(appointment: appointments[ip.row])
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tv: UITableView, trailingSwipeActionsConfigurationForRowAt ip: IndexPath) -> UISwipeActionsConfiguration? {
        let appt = appointments[ip.row]
        var actions: [UIContextualAction] = []

        if appt.status == .pending {
            let confirm = UIContextualAction(style: .normal, title: "Confirmar") { [weak self] _, _, done in
                self?.updateStatus(appt.id, status: "confirmed", at: ip)
                done(true)
            }
            confirm.backgroundColor = BarberTheme.blue
            actions.append(confirm)
        }

        let cancel = UIContextualAction(style: .destructive, title: "Cancelar") { [weak self] _, _, done in
            self?.updateStatus(appt.id, status: "cancelled", at: ip)
            done(true)
        }
        actions.append(cancel)
        return UISwipeActionsConfiguration(actions: actions)
    }
}

// MARK: - AppointmentRowCell
class AppointmentRowCell: UITableViewCell {

    private let card = UIView()
    private let colorStripe = UIView()
    private let timeLabel = UILabel()
    private let nameLabel = UILabel()
    private let detailLabel = UILabel()
    private let statusBadge = UIView()
    private let statusLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        card.backgroundColor = BarberTheme.surface
        card.layer.cornerRadius = 12
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 1
        card.layer.borderColor = BarberTheme.border.cgColor
        contentView.addSubview(card)

        colorStripe.layer.cornerRadius = 2
        card.addSubview(colorStripe)

        timeLabel.font = .monospacedSystemFont(ofSize: 13, weight: .bold)
        timeLabel.textColor = BarberTheme.gold

        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = BarberTheme.textPrimary

        detailLabel.font = .systemFont(ofSize: 12)
        detailLabel.textColor = BarberTheme.textSecond

        statusBadge.layer.cornerRadius = 8
        statusLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        statusBadge.addSubview(statusLabel)

        [timeLabel, nameLabel, detailLabel, statusBadge].forEach {
            card.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        colorStripe.translatesAutoresizingMaskIntoConstraints = false
        card.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            colorStripe.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            colorStripe.topAnchor.constraint(equalTo: card.topAnchor),
            colorStripe.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            colorStripe.widthAnchor.constraint(equalToConstant: 4),

            timeLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            timeLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),

            nameLabel.leadingAnchor.constraint(equalTo: timeLabel.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor),

            detailLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            detailLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 6),
            detailLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),

            statusBadge.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            statusBadge.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            statusBadge.heightAnchor.constraint(equalToConstant: 24),

            statusLabel.centerXAnchor.constraint(equalTo: statusBadge.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: statusBadge.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: statusBadge.leadingAnchor, constant: 10),
            statusLabel.trailingAnchor.constraint(equalTo: statusBadge.trailingAnchor, constant: -10),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with appt: Appointment) {
        let statusStr = appt.status.rawValue
        let color = BarberTheme.statusColor(statusStr)
        colorStripe.backgroundColor = color

        if let d = ISO8601DateFormatter().date(from: appt.appointmentDate) {
            let fmt = DateFormatter()
            fmt.dateFormat = "HH:mm"
            timeLabel.text = fmt.string(from: d)
        }
        nameLabel.text = appt.customerName
        detailLabel.text = "\(appt.barber.name)\(appt.service.map { " · \($0.name) · R$\(String(format: "%.0f", $0.price))" } ?? "")"

        statusLabel.text = BarberTheme.statusLabel(statusStr)
        statusLabel.textColor = color
        statusBadge.backgroundColor = color.withAlphaComponent(0.15)
        statusBadge.layer.borderWidth = 1
        statusBadge.layer.borderColor = color.withAlphaComponent(0.3).cgColor
    }
}
