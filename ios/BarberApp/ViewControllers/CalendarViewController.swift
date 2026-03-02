/*
 BarberApp — CalendarViewController
 LAYOUT:
 ┌─────────────────────────────────┐
 │  [< Mês/Ano >]  [Hoje] [+ Novo] │  <- Header
 ├─────────────────────────────────┤
 │  Dom Seg Ter Qua Qui Sex Sab    │  <- Dias da semana
 │   1   2   3   4   5   6   7    │
 │   8   9  10  11  12  13  14    │  <- Grid com dots coloridos por barbeiro
 ├─────────────────────────────────┤
 │ [Todos] [João] [Pedro] [Carlos] │  <- Filtro por barbeiro
 ├─────────────────────────────────┤
 │ AGENDAMENTOS DE [DIA SELECIONADO]│
 │  ┌──────────────────────────┐   │
 │  │ 09:00 • Corte            │   │  <- AppointmentCard
 │  │ João Silva               │   │
 │  │ 💈 João  ● Confirmado    │   │
 │  └──────────────────────────┘   │
 └─────────────────────────────────┘
 */

import UIKit

class CalendarViewController: UIViewController {

    // MARK: - Properties
    var selectedDate: Date = Date()
    var appointments: [Appointment] = []
    var barbers: [BarberInfo] = []
    var selectedBarberId: String? = nil // nil = todos
    var daysWithAppointments: [String: [String]] = [:]
    var baseURL: String = AuthService.productionBaseURL
    var apiKey: String = ""

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let headerStack = UIStackView()
    private let monthLabel = UILabel()
    private let todayButton = UIButton(type: .system)
    private let newButton = UIButton(type: .system)
    private let prevButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let calendarCollectionView: UICollectionView
    private let barberFilterScrollView = UIScrollView()
    private let barberFilterStack = UIStackView()
    private let appointmentsTableStack = UIStackView()
    private let selectedDayLabel = UILabel()
    private let refreshControl = UIRefreshControl()

    private let calendarLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return layout
    }()

    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "pt_BR")
        return f
    }()

    private lazy var monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        f.locale = Locale(identifier: "pt_BR")
        return f
    }()

    /// Formato para exibição: "01 de Março/26"
    private lazy var displayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd 'de' MMMM/yy"
        f.locale = Locale(identifier: "pt_BR")
        return f
    }()

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.calendarCollectionView = UICollectionView(frame: .zero, collectionViewLayout: calendarLayout)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        self.calendarCollectionView = UICollectionView(frame: .zero, collectionViewLayout: calendarLayout)
        super.init(coder: coder)
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BarberAppTheme.background
        setupUI()
        loadBarbers()
        loadMonthDots()
        loadAppointments()
    }

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        scrollView.refreshControl = refreshControl

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        // Header: [< Mês/Ano >] [Hoje] [+ Novo]
        headerStack.axis = .horizontal
        headerStack.spacing = 12
        headerStack.alignment = .center
        prevButton.setTitle("<", for: .normal)
        prevButton.tintColor = BarberAppTheme.textPrimary
        prevButton.addTarget(self, action: #selector(prevMonth), for: .touchUpInside)
        nextButton.setTitle(">", for: .normal)
        nextButton.tintColor = BarberAppTheme.textPrimary
        nextButton.addTarget(self, action: #selector(nextMonth), for: .touchUpInside)
        monthLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        monthLabel.textColor = BarberAppTheme.gold
        todayButton.setTitle("Hoje", for: .normal)
        todayButton.tintColor = BarberAppTheme.gold
        todayButton.addTarget(self, action: #selector(goToday), for: .touchUpInside)
        newButton.setTitle("+ Novo", for: .normal)
        newButton.tintColor = BarberAppTheme.gold
        newButton.addTarget(self, action: #selector(newAppointment), for: .touchUpInside)
        headerStack.addArrangedSubview(prevButton)
        headerStack.addArrangedSubview(monthLabel)
        headerStack.addArrangedSubview(nextButton)
        headerStack.addArrangedSubview(UIView())
        headerStack.addArrangedSubview(todayButton)
        headerStack.addArrangedSubview(newButton)
        contentStack.addArrangedSubview(headerStack)

        // Calendar grid
        calendarCollectionView.backgroundColor = BarberAppTheme.card
        calendarCollectionView.layer.cornerRadius = 12
        calendarCollectionView.delegate = self
        calendarCollectionView.dataSource = self
        calendarCollectionView.register(CalendarDayCell.self, forCellWithReuseIdentifier: CalendarDayCell.reuseId)
        calendarCollectionView.register(CalendarHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: CalendarHeaderView.reuseId)
        calendarCollectionView.translatesAutoresizingMaskIntoConstraints = false
        calendarCollectionView.heightAnchor.constraint(equalToConstant: 240).isActive = true
        contentStack.addArrangedSubview(calendarCollectionView)

        // Barbers filter
        barberFilterScrollView.showsHorizontalScrollIndicator = false
        barberFilterStack.axis = .horizontal
        barberFilterStack.spacing = 8
        barberFilterStack.translatesAutoresizingMaskIntoConstraints = false
        barberFilterScrollView.addSubview(barberFilterStack)
        contentStack.addArrangedSubview(barberFilterScrollView)
        NSLayoutConstraint.activate([
            barberFilterScrollView.heightAnchor.constraint(equalToConstant: 44)
        ])
        NSLayoutConstraint.activate([
            barberFilterStack.leadingAnchor.constraint(equalTo: barberFilterScrollView.leadingAnchor),
            barberFilterStack.trailingAnchor.constraint(equalTo: barberFilterScrollView.trailingAnchor),
            barberFilterStack.topAnchor.constraint(equalTo: barberFilterScrollView.topAnchor),
            barberFilterStack.bottomAnchor.constraint(equalTo: barberFilterScrollView.bottomAnchor),
        ])

        // Appointments
        selectedDayLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        selectedDayLabel.textColor = BarberAppTheme.textPrimary
        selectedDayLabel.text = "Agendamentos"
        contentStack.addArrangedSubview(selectedDayLabel)
        appointmentsTableStack.axis = .vertical
        appointmentsTableStack.spacing = 12
        contentStack.addArrangedSubview(appointmentsTableStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])

        updateMonthLabel()
    }

    private func updateMonthLabel() {
        monthLabel.text = monthYearFormatter.string(from: selectedDate).capitalized
        selectedDayLabel.text = "Agendamentos de \(displayDateFormatter.string(from: selectedDate))"
    }

    // MARK: - Actions
    @objc private func prevMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: selectedDate) {
            selectedDate = newDate
            updateMonthLabel()
            loadMonthDots()
            calendarCollectionView.reloadData()
        }
    }

    @objc private func nextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: selectedDate) {
            selectedDate = newDate
            updateMonthLabel()
            loadMonthDots()
            calendarCollectionView.reloadData()
        }
    }

    @objc private func goToday() {
        selectedDate = Date()
        updateMonthLabel()
        loadMonthDots()
        loadAppointments()
        calendarCollectionView.reloadData()
    }

    @objc private func newAppointment() {
        // TODO: apresentar tela de novo agendamento
    }

    @objc private func refreshData() {
        loadMonthDots()
        loadAppointments()
        loadBarbers()
        refreshControl.endRefreshing()
    }

    private func selectBarber(_ id: String?) {
        selectedBarberId = id
        loadAppointments()
        // Atualizar UI dos botões
    }

    // MARK: - API
    private func loadBarbers() {
        guard let url = URL(string: "\(baseURL)/api/app/barbers") else { return }
        var req = URLRequest(url: url)
        req.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            guard let data = data,
                  let barbers = try? JSONDecoder().decode([BarberInfo].self, from: data) else { return }
            DispatchQueue.main.async {
                self?.barbers = barbers
                self?.updateBarberFilter()
            }
        }.resume()
    }

    private func updateBarberFilter() {
        barberFilterStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let allBtn = createBarberButton(title: "Todos", barberId: nil)
        barberFilterStack.addArrangedSubview(allBtn)
        for b in barbers {
            let btn = createBarberButton(title: b.name, barberId: b.id)
            barberFilterStack.addArrangedSubview(btn)
        }
    }

    private func createBarberButton(title: String, barberId: String?) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.tintColor = BarberAppTheme.gold
        btn.addAction(UIAction { [weak self] _ in
            self?.selectedBarberId = barberId
            self?.loadAppointments()
        }, for: .touchUpInside)
        return btn
    }

    private func loadMonthDots() {
        let month = dateFormatter.string(from: selectedDate).prefix(7)
        guard let url = URL(string: "\(baseURL)/api/app/appointments/month?month=\(month)") else { return }
        var req = URLRequest(url: url)
        req.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let days = json["days_with_appointments"] as? [String: [String: Any]] else {
                DispatchQueue.main.async { self?.daysWithAppointments = [:] }
                return
            }
            let result = days.mapValues { ($0["statuses"] as? [String]) ?? [] }
            DispatchQueue.main.async {
                self?.daysWithAppointments = result
                self?.calendarCollectionView.reloadData()
            }
        }.resume()
    }

    private func loadAppointments() {
        let dateStr = dateFormatter.string(from: selectedDate)
        var urlStr = "\(baseURL)/api/app/appointments?date=\(dateStr)"
        if let barberId = selectedBarberId {
            urlStr += "&barber_id=\(barberId)"
        }
        guard let url = URL(string: urlStr) else { return }
        var req = URLRequest(url: url)
        req.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        URLSession.shared.dataTask(with: req) { [weak self] data, _, _ in
            guard let data = data,
                  let json = try? JSONDecoder().decode(AppointmentsResponse.self, from: data) else {
                DispatchQueue.main.async { self?.reloadAppointmentsTable([]) }
                return
            }
            DispatchQueue.main.async {
                self?.appointments = json.appointments
                self?.reloadAppointmentsTable(json.appointments)
            }
        }.resume()
    }

    private func reloadAppointmentsTable(_ list: [Appointment]) {
        appointmentsTableStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for a in list {
            let card = AppointmentCardView(appointment: a)
            appointmentsTableStack.addArrangedSubview(card)
        }
    }
}

struct AppointmentsResponse: Codable {
    let appointments: [Appointment]
}

// MARK: - UICollectionView
extension CalendarViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let cal = Calendar.current
        let range = cal.range(of: .day, in: .month, for: selectedDate)!
        let firstWeekday = cal.component(.weekday, from: cal.date(from: cal.dateComponents([.year, .month], from: selectedDate))!) - 1
        return range.count + firstWeekday
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CalendarDayCell.reuseId, for: indexPath) as! CalendarDayCell
        let cal = Calendar.current
        let firstWeekday = cal.component(.weekday, from: cal.date(from: cal.dateComponents([.year, .month], from: selectedDate))!) - 1
        if indexPath.item < firstWeekday {
            cell.configure(day: nil, hasAppointments: false, isSelected: false, isToday: false)
        } else {
            let day = indexPath.item - firstWeekday + 1
            let dateStr = String(format: "%04d-%02d-%02d",
                                cal.component(.year, from: selectedDate),
                                cal.component(.month, from: selectedDate),
                                day)
            let hasAppointments = !(daysWithAppointments[dateStr] ?? []).isEmpty
            let comps = DateComponents(year: cal.component(.year, from: selectedDate), month: cal.component(.month, from: selectedDate), day: day)
            let cellDate = cal.date(from: comps) ?? selectedDate
            let isSelected = cal.isDate(selectedDate, inSameDayAs: cellDate)
            let isToday = cal.isDateInToday(cellDate)
            cell.configure(day: day, hasAppointments: hasAppointments, isSelected: isSelected, isToday: isToday)
            cell.onTap = { [weak self] in
                if let d = cal.date(from: DateComponents(year: cal.component(.year, from: self!.selectedDate), month: cal.component(.month, from: self!.selectedDate), day: day)) {
                    self?.selectedDate = d
                    self?.updateMonthLabel()
                    self?.loadAppointments()
                    collectionView.reloadData()
                }
            }
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = (collectionView.bounds.width - 16 - 8*6) / 7
        return CGSize(width: w, height: 36)
    }
}

// MARK: - Cells & Views
class CalendarDayCell: UICollectionViewCell {
    static let reuseId = "CalendarDayCell"
    private let label = UILabel()
    private let dotView = UIView()
    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)
        dotView.backgroundColor = .systemOrange
        dotView.layer.cornerRadius = 3
        dotView.translatesAutoresizingMaskIntoConstraints = false
        dotView.isHidden = true
        contentView.addSubview(dotView)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            dotView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dotView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 2),
            dotView.widthAnchor.constraint(equalToConstant: 6),
            dotView.heightAnchor.constraint(equalToConstant: 6)
        ])
        contentView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        contentView.addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(day: Int?, hasAppointments: Bool, isSelected: Bool, isToday: Bool) {
        label.text = day.map { "\($0)" } ?? ""
        dotView.isHidden = !hasAppointments
        dotView.backgroundColor = BarberAppTheme.gold
        contentView.backgroundColor = isSelected ? BarberAppTheme.gold : (isToday ? BarberAppTheme.goldDim : .clear)
        contentView.layer.cornerRadius = 8
        label.textColor = isSelected ? BarberAppTheme.background : (hasAppointments ? BarberAppTheme.textPrimary : BarberAppTheme.textSecondary)
    }

    @objc private func tapped() { onTap?() }
}

class CalendarHeaderView: UICollectionReusableView {
    static let reuseId = "CalendarHeaderView"
}

class AppointmentCardView: UIView {
    private let timeLabel = UILabel()
    private let serviceLabel = UILabel()
    private let customerLabel = UILabel()
    private let statusBadge = UILabel()

    init(appointment: Appointment) {
        super.init(frame: .zero)
        backgroundColor = BarberAppTheme.card
        layer.cornerRadius = 12
        timeLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        timeLabel.textColor = BarberAppTheme.gold
        serviceLabel.font = .systemFont(ofSize: 14, weight: .medium)
        serviceLabel.textColor = BarberAppTheme.textPrimary
        customerLabel.font = .systemFont(ofSize: 12)
        customerLabel.textColor = BarberAppTheme.textSecondary
        statusBadge.font = .systemFont(ofSize: 11, weight: .medium)
        statusBadge.textAlignment = .center
        statusBadge.layer.cornerRadius = 4
        statusBadge.clipsToBounds = true
        let stack = UIStackView(arrangedSubviews: [timeLabel, serviceLabel, customerLabel, statusBadge])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
        let time = ISO8601DateFormatter().date(from: appointment.appointmentDate).map {
            DateFormatter.localizedString(from: $0, dateStyle: .none, timeStyle: .short)
        } ?? "-"
        timeLabel.text = "\(time) • \(appointment.service?.name ?? "-")"
        customerLabel.text = appointment.customerName
        statusBadge.text = " \(appointment.status.displayName) "
        statusBadge.backgroundColor = appointment.status.color.withAlphaComponent(0.3)
        statusBadge.textColor = appointment.status.color
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
