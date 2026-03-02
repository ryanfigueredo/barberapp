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

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

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
        segmentControl.autoresizingMask = [.flexibleWidth]

        let w = max(view.bounds.width, UIScreen.main.bounds.width)
        let headerW = w > 0 ? w : 320
        let container = UIView(frame: CGRect(x: 0, y: 0, width: headerW, height: 52))
        container.addSubview(segmentControl)
        segmentControl.frame = CGRect(x: 16, y: 8, width: headerW - 32, height: 36)
        tableView.tableHeaderView = container
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let w = tableView.bounds.width
        guard w > 0, let header = tableView.tableHeaderView else { return }
        if abs(header.bounds.width - w) > 1 {
            header.frame = CGRect(x: 0, y: 0, width: w, height: 52)
            segmentControl.frame = CGRect(x: 16, y: 8, width: w - 32, height: 36)
        }
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
                    // Excluídos (cancelados) saem da lista: mostrar apenas próximos/ativos
                    self?.appointments = r.appointments.filter { $0.status != .cancelled }
                    self?.tableView.reloadData()
                    AppointmentNotificationService.shared.scheduleForAppointments(r.appointments)
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

    /// Desmarca o corte: pergunta motivo, cancela e avisa o cliente no WhatsApp.
    private func desmarcarAgendamento(_ appt: Appointment, at ip: IndexPath) {
        let motivos = ["Cliente solicitou", "Reagendamento", "Falta de disponibilidade", "Horário indisponível", "Outro"]
        let alert = UIAlertController(title: "Desmarcar agendamento", message: "Escolha o motivo. Uma mensagem será enviada ao cliente no WhatsApp.", preferredStyle: .actionSheet)
        for motivo in motivos {
            alert.addAction(UIAlertAction(title: motivo, style: .default) { [weak self] _ in
                if motivo == "Outro" {
                    self?.pedirMotivoOutro(appt: appt, at: ip)
                } else if motivo == "Reagendamento" {
                    self?.abrirReagendamento(appt: appt, at: ip)
                } else {
                    self?.confirmarDesmarcar(appt, motivo: motivo, at: ip)
                }
            })
        }
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        if let popover = alert.popoverPresentationController, let cell = tableView.cellForRow(at: ip) {
            popover.sourceView = cell
            popover.sourceRect = cell.bounds
        }
        present(alert, animated: true)
    }

    /// Escolher novo dia e horário e reagendar (atualiza agendamento e avisa no WhatsApp).
    private func abrirReagendamento(appt: Appointment, at ip: IndexPath) {
        let vc = ReagendarViewController(appointment: appt)
        vc.onReagendar = { [weak self] newDate in
            self?.confirmarReagendar(appt, novaData: newDate, at: ip)
        }
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .pageSheet
        present(nav, animated: true)
    }

    private func confirmarReagendar(_ appt: Appointment, novaData: Date, at ip: IndexPath) {
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .short
        fmt.locale = Locale(identifier: "pt_BR")
        let dataStr = fmt.string(from: novaData)
        let msg = "Seu agendamento foi reagendado para \(dataStr). Qualquer dúvida, entre em contato."
        ApiService.shared.updateAppointmentDate(id: appt.id, appointmentDate: novaData) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    ApiService.shared.sendWhatsAppMessage(phone: appt.customerPhone, message: msg) { _ in }
                    self?.loadAppointments()
                case .failure:
                    let alert = UIAlertController(title: "Erro", message: "Não foi possível reagendar.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }

    private func pedirMotivoOutro(appt: Appointment, at ip: IndexPath) {
        let alert = UIAlertController(title: "Motivo do cancelamento", message: "Digite o motivo para enviar ao cliente.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Ex: Horário indisponível" }
        alert.addAction(UIAlertAction(title: "Desmarcar", style: .destructive) { [weak self] _ in
            let motivo = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                ? (alert.textFields?.first?.text ?? "Outro")
                : "Motivo não informado"
            self?.confirmarDesmarcar(appt, motivo: motivo, at: ip)
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    private func confirmarDesmarcar(_ appt: Appointment, motivo: String, at ip: IndexPath) {
        let msg = "Seu agendamento foi desmarcado. Motivo: \(motivo). Qualquer dúvida, entre em contato."
        ApiService.shared.updateAppointmentStatus(id: appt.id, status: "cancelled") { [weak self] _ in
            ApiService.shared.sendWhatsAppMessage(phone: appt.customerPhone, message: msg) { _ in }
            DispatchQueue.main.async {
                self?.loadAppointments()
            }
        }
    }

    private func marcarConcluido(_ appt: Appointment, at ip: IndexPath) {
        ApiService.shared.updateAppointmentStatus(id: appt.id, status: "completed") { [weak self] _ in
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
        let appt = appointments[ip.row]
        cell.configure(
            with: appt,
            onVerDetalhes: { [weak self] in
                let vc = AppointmentDetailViewController(appointment: appt)
                self?.navigationController?.pushViewController(vc, animated: true)
            },
            onConcluir: { [weak self] in
                self?.marcarConcluido(appt, at: ip)
            },
            onDesmarcar: { [weak self] in
                self?.desmarcarAgendamento(appt, at: ip)
            }
        )
        return cell
    }

    func tableView(_ tv: UITableView, didSelectRowAt ip: IndexPath) {
        tv.deselectRow(at: ip, animated: true)
        let vc = AppointmentDetailViewController(appointment: appointments[ip.row])
        navigationController?.pushViewController(vc, animated: true)
    }

    func tableView(_ tv: UITableView, trailingSwipeActionsConfigurationForRowAt ip: IndexPath) -> UISwipeActionsConfiguration? {
        nil
    }
}

// MARK: - AppointmentRowCell
class AppointmentRowCell: UITableViewCell {

    private let card = UIView()
    private let colorStripe = UIView()
    private let timeLabel = UILabel()
    private let nameLabel = UILabel()
    private let detailLabel = UILabel()
    private let iconsStack = UIStackView()
    private let btnVer = UIButton(type: .system)
    private let btnConcluir = UIButton(type: .system)
    private let btnDesmarcar = UIButton(type: .system)

    private var onVerDetalhes: (() -> Void)?
    private var onConcluir: (() -> Void)?
    private var onDesmarcar: (() -> Void)?

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

        let iconSize: CGFloat = 14
        let circleSize: CGFloat = 32
        let cfg = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .medium)

        btnVer.setImage(UIImage(systemName: "eye.fill", withConfiguration: cfg), for: .normal)
        btnVer.tintColor = BarberTheme.gold
        btnVer.backgroundColor = BarberTheme.gold.withAlphaComponent(0.2)
        btnVer.layer.cornerRadius = circleSize / 2
        btnVer.clipsToBounds = true
        btnVer.addTarget(self, action: #selector(tappedVer), for: .touchUpInside)

        btnConcluir.setImage(UIImage(systemName: "checkmark", withConfiguration: cfg), for: .normal)
        btnConcluir.tintColor = BarberTheme.success
        btnConcluir.backgroundColor = BarberTheme.success.withAlphaComponent(0.2)
        btnConcluir.layer.cornerRadius = circleSize / 2
        btnConcluir.clipsToBounds = true
        btnConcluir.addTarget(self, action: #selector(tappedConcluir), for: .touchUpInside)

        btnDesmarcar.setImage(UIImage(systemName: "trash.fill", withConfiguration: cfg), for: .normal)
        btnDesmarcar.tintColor = BarberTheme.danger
        btnDesmarcar.backgroundColor = BarberTheme.danger.withAlphaComponent(0.2)
        btnDesmarcar.layer.cornerRadius = circleSize / 2
        btnDesmarcar.clipsToBounds = true
        btnDesmarcar.addTarget(self, action: #selector(tappedDesmarcar), for: .touchUpInside)

        [btnVer, btnConcluir, btnDesmarcar].forEach { btn in
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.widthAnchor.constraint(equalToConstant: circleSize).isActive = true
            btn.heightAnchor.constraint(equalToConstant: circleSize).isActive = true
        }

        iconsStack.axis = .horizontal
        iconsStack.spacing = 8
        iconsStack.alignment = .center
        iconsStack.addArrangedSubview(btnVer)
        iconsStack.addArrangedSubview(btnConcluir)
        iconsStack.addArrangedSubview(btnDesmarcar)
        card.addSubview(iconsStack)

        [timeLabel, nameLabel, detailLabel].forEach {
            card.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        colorStripe.translatesAutoresizingMaskIntoConstraints = false
        card.translatesAutoresizingMaskIntoConstraints = false
        iconsStack.translatesAutoresizingMaskIntoConstraints = false

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
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: iconsStack.leadingAnchor, constant: -8),

            detailLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            detailLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 6),
            detailLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),

            iconsStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
            iconsStack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    @objc private func tappedVer() { onVerDetalhes?() }
    @objc private func tappedConcluir() { onConcluir?() }
    @objc private func tappedDesmarcar() { onDesmarcar?() }

    func configure(
        with appt: Appointment,
        onVerDetalhes: @escaping () -> Void,
        onConcluir: @escaping () -> Void,
        onDesmarcar: @escaping () -> Void
    ) {
        self.onVerDetalhes = onVerDetalhes
        self.onConcluir = onConcluir
        self.onDesmarcar = onDesmarcar

        let color = BarberTheme.statusColor(appt.status.rawValue)
        colorStripe.backgroundColor = color

        if let d = ISO8601DateFormatter().date(from: appt.appointmentDate) {
            let fmt = DateFormatter()
            fmt.dateFormat = "HH:mm"
            timeLabel.text = fmt.string(from: d)
        }
        nameLabel.text = appt.customerName
        detailLabel.text = "\(appt.barber.name)\(appt.service.map { " · \($0.name) · R$\(String(format: "%.0f", $0.price))" } ?? "")"

        btnVer.isHidden = false
        btnConcluir.isHidden = !(appt.status == .pending || appt.status == .confirmed || appt.status == .inProgress)
        btnDesmarcar.isHidden = !(appt.status == .pending || appt.status == .confirmed)
    }
}

// MARK: - ReagendarViewController
/// Modal para escolher novo dia e horário ao reagendar um agendamento.
final class ReagendarViewController: UIViewController {

    private let appointment: Appointment
    private let datePicker = UIDatePicker()
    var onReagendar: ((Date) -> Void)?

    init(appointment: Appointment) {
        self.appointment = appointment
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Novo dia e horário"
        view.backgroundColor = BarberTheme.bg
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelar))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Reagendar", style: .done, target: self, action: #selector(reagendar))
        navigationItem.rightBarButtonItem?.tintColor = BarberTheme.gold

        datePicker.datePickerMode = .dateAndTime
        datePicker.minimumDate = Date()
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.backgroundColor = BarberTheme.surface
        datePicker.tintColor = BarberTheme.gold
        if let d = ISO8601DateFormatter().date(from: appointment.appointmentDate) {
            datePicker.date = d > Date() ? d : Date()
        }
        view.addSubview(datePicker)
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            datePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            datePicker.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
        ])
    }

    @objc private func cancelar() {
        dismiss(animated: true)
    }

    @objc private func reagendar() {
        onReagendar?(datePicker.date)
        dismiss(animated: true)
    }
}
