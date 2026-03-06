//
//  CalendarViewController.swift
//  BarberApp
//
//  Calendário com 3 modos: Dia (esteira) / Semana / Mês (com dots)
//

import UIKit

// MARK: - Notification names
extension Notification.Name {
    static let appointmentCreated = Notification.Name("appointmentCreated")
}

// MARK: - CalendarMode
enum CalendarMode { case day, week, month }

// MARK: - CalendarViewController
class CalendarViewController: UIViewController {

    private var mode: CalendarMode = .month
    private var selectedDate = Date()
    private var allAppointments: [Appointment] = []
    private var monthDots: [String: Int] = [:]
    private var selectedBarberId: String?
    /// Quando true, ao terminar loadAppointments em modo mês, apresenta o sheet do dia selecionado.
    private var showDaySheetAfterLoad = false

    private let scrollView = UIScrollView()
    private let modeSegment = UISegmentedControl(items: ["Dia", "Semana", "Mês"])
    private let monthGridView = MonthCalendarView()
    private let dayTimelineView = DayTimelineView()
    private let weekGridView = WeekGridView()
    private let filterBar = BarberFilterBar()
    private let refreshControl = UIRefreshControl()
    private let dayDetailSection = UIStackView()
    private let selectedDateLabel = UILabel()
    private let appointmentsListView = AppointmentsDayListView()

    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "pt_BR")
        return f
    }()

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BarberTheme.bg
        setupNav()
        setupSegment()
        setupBarberFilter()
        setupScrollView()
        setupViews()
        switchMode(.month, animated: false)
        loadMonthDots()
        loadAppointments()
        updateSelectedDateLabel()

        NotificationCenter.default.addObserver(self, selector: #selector(reloadAfterCreate),
                                              name: .appointmentCreated, object: nil)
    }

    @objc private func reloadAfterCreate() {
        loadMonthDots()
        loadAppointments()
    }

    private func setupNav() {
        title = "Calendário"
        navigationController?.navigationBar.prefersLargeTitles = true
        let settings = UIBarButtonItem(
            image: UIImage(systemName: "gearshape.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)),
            style: .plain, target: self, action: #selector(openSettings))
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "+ Novo", style: .plain, target: self, action: #selector(newAppointment)),
            UIBarButtonItem(title: "Hoje", style: .plain, target: self, action: #selector(goToToday)),
            settings,
        ]
        navigationItem.rightBarButtonItems?.forEach { $0.tintColor = BarberTheme.gold }
    }

    @objc private func openSettings() {
        let nav = UINavigationController(rootViewController: SettingsViewController())
        let a = UINavigationBarAppearance()
        a.configureWithOpaqueBackground()
        a.backgroundColor = UIColor(white: 0.05, alpha: 1)
        a.titleTextAttributes = [.foregroundColor: BarberTheme.gold]
        nav.navigationBar.standardAppearance = a
        nav.navigationBar.scrollEdgeAppearance = a
        nav.navigationBar.tintColor = BarberTheme.gold
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }

    private func setupSegment() {
        modeSegment.selectedSegmentIndex = 2
        modeSegment.backgroundColor = BarberTheme.surface
        modeSegment.selectedSegmentTintColor = BarberTheme.gold
        modeSegment.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 13, weight: .medium)], for: .normal)
        modeSegment.setTitleTextAttributes([.foregroundColor: UIColor.black, .font: UIFont.systemFont(ofSize: 13, weight: .bold)], for: .selected)
        modeSegment.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        view.addSubview(modeSegment)
        modeSegment.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            modeSegment.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            modeSegment.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            modeSegment.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            modeSegment.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    private func setupBarberFilter() {
        view.addSubview(filterBar)
        filterBar.translatesAutoresizingMaskIntoConstraints = false
        filterBar.onFilter = { [weak self] barberId in
            self?.selectedBarberId = barberId
            self?.filterBar.setSelectedBarberId(barberId)
            self?.loadMonthDots()
            self?.loadAppointments()
        }
        NSLayoutConstraint.activate([
            filterBar.topAnchor.constraint(equalTo: modeSegment.bottomAnchor, constant: 8),
            filterBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            filterBar.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    private func setupScrollView() {
        scrollView.showsVerticalScrollIndicator = false
        refreshControl.tintColor = BarberTheme.gold
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        scrollView.refreshControl = refreshControl
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: filterBar.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func setupViews() {
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 12
        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -16),
        ])

        contentStack.addArrangedSubview(monthGridView)
        contentStack.addArrangedSubview(dayTimelineView)
        contentStack.addArrangedSubview(weekGridView)

        contentStack.addArrangedSubview(dayDetailSection)
        dayDetailSection.addArrangedSubview(selectedDateLabel)
        dayDetailSection.addArrangedSubview(appointmentsListView)

        monthGridView.onDaySelected = { [weak self] date in
            self?.selectedDate = date
            self?.updateSelectedDateLabel()
            self?.showDaySheetAfterLoad = (self?.mode == .month)
            self?.loadAppointments()
        }
        monthGridView.onSwipeMonth = { [weak self] direction in
            guard let self else { return }
            if let d = Calendar.current.date(byAdding: .month, value: direction, to: selectedDate) {
                selectedDate = d
                monthGridView.setCurrentDate(d)
                loadMonthDots()
            }
        }

        dayDetailSection.axis = .vertical
        dayDetailSection.spacing = 12
    }

    private func updateSelectedDateLabel() {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, d 'de' MMMM"
        fmt.locale = Locale(identifier: "pt_BR")
        selectedDateLabel.text = fmt.string(from: selectedDate).capitalized
        selectedDateLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        selectedDateLabel.textColor = BarberTheme.textSecond
    }

    @objc private func segmentChanged() {
        let modes: [CalendarMode] = [.day, .week, .month]
        switchMode(modes[modeSegment.selectedSegmentIndex])
    }

    private func switchMode(_ newMode: CalendarMode, animated: Bool = true) {
        mode = newMode
        let block = {
            self.monthGridView.isHidden = newMode != .month
            self.dayTimelineView.isHidden = newMode != .day
            self.weekGridView.isHidden = newMode != .week
            self.dayDetailSection.isHidden = newMode != .month
            self.filterBar.isHidden = false
        }
        if animated {
            UIView.animate(withDuration: 0.2, animations: block)
        } else {
            block()
        }
        loadAppointments()
    }

    private func loadAppointments() {
        let dateStr = dateFormatter.string(from: selectedDate)
        var path: String
        switch mode {
        case .day, .month:
            path = "/api/app/appointments?date=\(dateStr)"
        case .week:
            let cal = Calendar.current
            let sun = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)) ?? selectedDate
            let sat = cal.date(byAdding: .day, value: 6, to: sun) ?? sun
            path = "/api/app/appointments?start=\(dateFormatter.string(from: sun))&end=\(dateFormatter.string(from: sat))"
        }
        if let barberId = selectedBarberId, !barberId.isEmpty {
            path += "&barber_id=\(barberId)"
        }

        ApiService.shared.fetch(path) { [weak self] (result: Result<AppointmentsResponse, Error>) in
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
                if case .success(let resp) = result {
                    self?.allAppointments = resp.appointments
                    self?.applyFilter()
                    if self?.showDaySheetAfterLoad == true, self?.mode == .month {
                        self?.showDaySheetAfterLoad = false
                        self?.presentDayAppointmentsSheetIfNeeded()
                    }
                }
            }
        }
    }

    private func applyFilter() {
        let filtered = selectedBarberId == nil
            ? allAppointments
            : allAppointments.filter { $0.barber.id == selectedBarberId }
        reloadViews(with: filtered)
    }

    private func reloadViews(with appointments: [Appointment]) {
        switch mode {
        case .day:
            dayTimelineView.setAppointments(appointments, for: selectedDate)
        case .week:
            weekGridView.setAppointments(appointments, weekOf: selectedDate)
        case .month:
            monthGridView.setSelectedDate(selectedDate)
        }
        let cal = Calendar.current
        let dayFiltered = appointments.filter {
            guard let d = ISO8601DateFormatter().date(from: $0.appointmentDate) else { return false }
            return cal.isDate(d, inSameDayAs: selectedDate)
        }
        appointmentsListView.setAppointments(dayFiltered, for: selectedDate)
    }

    private func loadMonthDots() {
        let month = dateFormatter.string(from: selectedDate).prefix(7)
        var path = "/api/app/appointments/month?month=\(month)"
        if let barberId = selectedBarberId, !barberId.isEmpty {
            path += "&barber_id=\(barberId)"
        }
        ApiService.shared.fetch(path) { [weak self] (result: Result<MonthAppointmentsResponse, Error>) in
            DispatchQueue.main.async {
                if case .success(let resp) = result {
                    var dots: [String: Int] = [:]
                    resp.days_with_appointments?.forEach { day, info in
                        dots[day] = info.count ?? 0
                    }
                    self?.monthDots = dots
                    self?.monthGridView.setDots(dots)
                    self?.monthGridView.setCurrentDate(self?.selectedDate ?? Date())
                }
            }
        }
    }

    @objc private func goToToday() {
        selectedDate = Date()
        updateSelectedDateLabel()
        loadMonthDots()
        loadAppointments()
        modeSegment.selectedSegmentIndex = 2
        switchMode(.month)
    }

    @objc private func newAppointment() {
        let vc = NewAppointmentViewController()
        navigationController?.present(UINavigationController(rootViewController: vc), animated: true)
    }

    @objc private func handleRefresh() {
        loadMonthDots()
        loadAppointments()
    }

    private func presentDayAppointmentsSheetIfNeeded() {
        let cal = Calendar.current
        let dayAppointments = allAppointments.filter {
            guard let d = ISO8601DateFormatter().date(from: $0.appointmentDate) else { return false }
            return cal.isDate(d, inSameDayAs: selectedDate)
        }
        let sheet = DayAppointmentsSheetViewController(date: selectedDate, appointments: dayAppointments)
        sheet.onSelectAppointment = { [weak self] appt in
            self?.dismiss(animated: true) {
                let detail = AppointmentDetailViewController(appointment: appt)
                self?.navigationController?.pushViewController(detail, animated: true)
            }
        }
        let nav = UINavigationController(rootViewController: sheet)
        nav.modalPresentationStyle = .pageSheet
        if let sheetCtrl = nav.sheetPresentationController {
            sheetCtrl.detents = [.medium(), .large()]
            sheetCtrl.prefersGrabberVisible = true
        }
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = BarberTheme.bg
        appearance.titleTextAttributes = [.foregroundColor: BarberTheme.gold]
        nav.navigationBar.standardAppearance = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        nav.navigationBar.tintColor = BarberTheme.gold
        present(nav, animated: true)
    }
}

// MARK: - DayTimelineView
class DayTimelineView: UIView {

    private let scrollView = UIScrollView()
    private var appts: [Appointment] = []
    private var date = Date()

    private let hourHeight: CGFloat = 64
    private let leftPad: CGFloat = 56
    private let topPadding: CGFloat = 16
    private let startHour = 6
    private let endHour = 24   // 24 = renderiza até 23:00–23:59
    private var totalHours: Int { endHour - startHour }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(scrollView)
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 480),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func setAppointments(_ appointments: [Appointment], for date: Date) {
        appts = appointments
        self.date = date
        redraw()
        let targetHour = Calendar.current.isDateInToday(date)
            ? max(Calendar.current.component(.hour, from: Date()) - 1, startHour)
            : 8
        let y = CGFloat(targetHour - startHour) * hourHeight
        DispatchQueue.main.async {
            self.scrollView.setContentOffset(CGPoint(x: 0, y: max(0, y - 40)), animated: false)
        }
    }

    private func redraw() {
        scrollView.subviews.forEach { $0.removeFromSuperview() }

        let totalHeight = CGFloat(endHour - startHour) * hourHeight + topPadding + 32
        let contentWidth = bounds.width > 0 ? bounds.width : 375
        let contentView = UIView(frame: CGRect(x: 0, y: 0, width: contentWidth, height: totalHeight))
        scrollView.addSubview(contentView)
        scrollView.contentSize = contentView.frame.size

        for h in startHour...endHour {
            let y = CGFloat(h - startHour) * hourHeight + topPadding
            if h == endHour { break }   // não desenha label do "24:00"

            let label = h < 10 ? "0\(h):00" : "\(h):00"
            let lbl = UILabel()
            lbl.text = label
            lbl.font = .monospacedSystemFont(ofSize: 11, weight: .medium)
            lbl.textColor = BarberTheme.textMuted
            lbl.frame = CGRect(x: 8, y: y - 8, width: 44, height: 16)
            contentView.addSubview(lbl)

            let line = UIView()
            line.backgroundColor = BarberTheme.border
            line.frame = CGRect(x: leftPad, y: y, width: contentWidth - leftPad - 16, height: 0.5)
            contentView.addSubview(line)
        }

        if Calendar.current.isDateInToday(date) {
            let now = Date()
            let comps = Calendar.current.dateComponents([.hour, .minute], from: now)
            let h = CGFloat((comps.hour ?? 0) - startHour)
            let m = CGFloat(comps.minute ?? 0)
            let y = h * hourHeight + (m / 60) * hourHeight + topPadding

            let nowLine = UIView()
            nowLine.backgroundColor = BarberTheme.danger
            nowLine.frame = CGRect(x: leftPad - 4, y: y, width: contentWidth - leftPad - 12, height: 2)
            nowLine.layer.cornerRadius = 1
            contentView.addSubview(nowLine)

            let dot = UIView()
            dot.backgroundColor = BarberTheme.danger
            dot.frame = CGRect(x: leftPad - 8, y: y - 4, width: 8, height: 8)
            dot.layer.cornerRadius = 4
            contentView.addSubview(dot)
        }

        let colWidth = contentWidth - leftPad - 16
        for (idx, appt) in appts.enumerated() {
            guard let apptDate = ISO8601DateFormatter().date(from: appt.appointmentDate) else { continue }
            let apptComps = Calendar.current.dateComponents([.hour, .minute], from: apptDate)
            let h = CGFloat((apptComps.hour ?? 0) - startHour)
            let m = CGFloat(apptComps.minute ?? 0)
            let y = h * hourHeight + (m / 60) * hourHeight + topPadding

            let duration = CGFloat(appt.service?.durationMinutes ?? 60)
            let height = max((duration / 60.0) * hourHeight - 4, 44)

            let block = AppointmentTimeBlock()
            block.configure(with: appt)
            block.frame = CGRect(x: leftPad + 4, y: y + 2, width: colWidth - 4, height: height)
            block.layer.cornerRadius = 10
            block.layer.cornerCurve = .continuous
            block.tag = idx

            let tap = UITapGestureRecognizer(target: self, action: #selector(blockTapped(_:)))
            block.addGestureRecognizer(tap)
            block.isUserInteractionEnabled = true
            contentView.addSubview(block)
        }
    }

    @objc private func blockTapped(_ gr: UITapGestureRecognizer) {
        guard let vc = findViewController() as? CalendarViewController,
              let view = gr.view,
              view.tag < appts.count else { return }
        let appt = appts[view.tag]
        let detail = AppointmentDetailViewController(appointment: appt)
        vc.navigationController?.pushViewController(detail, animated: true)
    }
}

// MARK: - AppointmentTimeBlock
class AppointmentTimeBlock: UIView {
    private let colorBar = UIView()
    private let timeLabel = UILabel()
    private let nameLabel = UILabel()
    private let serviceLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = BarberTheme.surface
        layer.borderWidth = 1
        layer.borderColor = BarberTheme.border.cgColor
        clipsToBounds = true

        colorBar.frame = CGRect(x: 0, y: 0, width: 4, height: 0)
        addSubview(colorBar)

        [timeLabel, nameLabel, serviceLabel].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        timeLabel.font = .monospacedSystemFont(ofSize: 10, weight: .bold)
        timeLabel.textColor = BarberTheme.textMuted
        nameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        nameLabel.textColor = BarberTheme.textPrimary
        serviceLabel.font = .systemFont(ofSize: 11)
        serviceLabel.textColor = BarberTheme.textSecond

        NSLayoutConstraint.activate([
            timeLabel.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            timeLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            nameLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 2),
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            nameLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            serviceLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 1),
            serviceLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        colorBar.frame = CGRect(x: 0, y: 0, width: 4, height: bounds.height)
    }

    func configure(with appt: Appointment) {
        let statusStr = appt.status.rawValue
        let color = BarberTheme.statusColor(statusStr)
        colorBar.backgroundColor = color
        backgroundColor = color.withAlphaComponent(0.10)
        layer.borderColor = color.withAlphaComponent(0.25).cgColor

        if let d = ISO8601DateFormatter().date(from: appt.appointmentDate) {
            let fmt = DateFormatter()
            fmt.dateFormat = "HH:mm"
            timeLabel.text = fmt.string(from: d)
        }
        nameLabel.text = appt.customerName
        serviceLabel.text = "\(appt.barber.name)\(appt.service.map { " · \($0.name)" } ?? "")"
    }
}

// MARK: - MonthCalendarView
class MonthCalendarView: UIView {
    var onDaySelected: ((Date) -> Void)?
    var onSwipeMonth: ((Int) -> Void)?

    private var currentDate = Date()
    private var selectedDate = Date()
    private var dots: [String: Int] = [:]
    private let collectionView: UICollectionView
    private let monthYearLabel = UILabel()
    private let prevButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let headerStack = UIStackView()
    private let monthYearStack = UIStackView()

    private let dayNames = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
    private var days: [Date?] = []
    private var collectionHeight: CGFloat = 240
    private var heightConstraint: NSLayoutConstraint?
    private let monthFmt: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        f.locale = Locale(identifier: "pt_BR")
        return f
    }()

    override init(frame: CGRect) {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 2
        layout.minimumLineSpacing = 2
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(frame: frame)
        buildCalendar()
        addSwipeGestures()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func buildCalendar() {
        backgroundColor = BarberTheme.surface
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = BarberTheme.border.cgColor

        monthYearLabel.font = .systemFont(ofSize: 17, weight: .bold)
        monthYearLabel.textColor = BarberTheme.gold
        monthYearLabel.textAlignment = .center

        prevButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        prevButton.tintColor = BarberTheme.gold
        prevButton.addAction(UIAction { [weak self] _ in self?.onSwipeMonth?(-1) }, for: .touchUpInside)

        nextButton.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        nextButton.tintColor = BarberTheme.gold
        nextButton.addAction(UIAction { [weak self] _ in self?.onSwipeMonth?(1) }, for: .touchUpInside)

        monthYearStack.axis = .horizontal
        monthYearStack.alignment = .center
        monthYearStack.distribution = .equalSpacing
        monthYearStack.addArrangedSubview(prevButton)
        monthYearStack.addArrangedSubview(monthYearLabel)
        monthYearStack.addArrangedSubview(nextButton)
        addSubview(monthYearStack)

        headerStack.distribution = .fillEqually
        dayNames.forEach { name in
            let lbl = UILabel()
            lbl.text = name
            lbl.font = .systemFont(ofSize: 11, weight: .semibold)
            lbl.textColor = BarberTheme.textMuted
            lbl.textAlignment = .center
            headerStack.addArrangedSubview(lbl)
        }
        addSubview(headerStack)

        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.register(DayCell.self, forCellWithReuseIdentifier: "day")
        collectionView.delegate = self
        collectionView.dataSource = self
        addSubview(collectionView)

        generateDays()
        updateMonthLabel()
        updateHeightConstraint()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        updateHeightConstraint()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }
        let pad: CGFloat = 8
        let topPad: CGFloat = 12
        let monthH: CGFloat = 36
        let headerH: CGFloat = 20
        let gap: CGFloat = 8

        monthYearStack.frame = CGRect(x: pad, y: topPad, width: bounds.width - pad * 2, height: monthH)
        headerStack.frame = CGRect(x: pad, y: topPad + monthH + 4, width: bounds.width - pad * 2, height: headerH)
        collectionView.frame = CGRect(
            x: pad, y: topPad + monthH + 4 + headerH + gap,
            width: bounds.width - pad * 2,
            height: min(collectionHeight, bounds.height - topPad - monthH - headerH - gap - topPad - 20)
        )
    }

    private func updateMonthLabel() {
        monthYearLabel.text = monthFmt.string(from: currentDate).capitalized
        generateDays()
        collectionView.reloadData()
    }

    private func addSwipeGestures() {
        let left = UISwipeGestureRecognizer(target: self, action: #selector(swiped(_:)))
        left.direction = .left
        let right = UISwipeGestureRecognizer(target: self, action: #selector(swiped(_:)))
        right.direction = .right
        addGestureRecognizer(left)
        addGestureRecognizer(right)
    }

    @objc private func swiped(_ gr: UISwipeGestureRecognizer) {
        onSwipeMonth?(gr.direction == .left ? 1 : -1)
    }

    private func generateDays() {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: currentDate)
        guard let first = cal.date(from: comps), let range = cal.range(of: .day, in: .month, for: first) else { return }
        let weekday = cal.component(.weekday, from: first) - 1

        days = Array(repeating: nil, count: weekday)
        for d in 1...range.count {
            days.append(cal.date(bySetting: .day, value: d, of: first))
        }
        while days.count % 7 != 0 { days.append(nil) }
        updateCollectionHeight()
    }

    private func updateCollectionHeight() {
        let weeks = max(1, Int(ceil(Double(days.count) / 7.0)))
        let itemH: CGFloat = 40
        let gap: CGFloat = 4
        collectionHeight = CGFloat(weeks) * itemH + CGFloat(max(0, weeks - 1)) * gap
        updateHeightConstraint()
        setNeedsLayout()
        layoutIfNeeded()
    }

    private func updateHeightConstraint() {
        let topPad: CGFloat = 12
        let monthH: CGFloat = 36
        let headerH: CGFloat = 20
        let gap: CGFloat = 8
        let bottomPad: CGFloat = 12
        let total = topPad + monthH + 4 + headerH + gap + collectionHeight + bottomPad

        if let c = heightConstraint {
            c.constant = total
        } else {
            heightConstraint = heightAnchor.constraint(equalToConstant: total)
            heightConstraint?.priority = .defaultHigh
            heightConstraint?.isActive = true
        }
    }

    func setDots(_ dots: [String: Int]) {
        self.dots = dots
        collectionView.reloadData()
    }

    func setCurrentDate(_ date: Date) {
        currentDate = date
        updateMonthLabel()
    }

    func setSelectedDate(_ date: Date) {
        selectedDate = date
        collectionView.reloadData()
    }
}

extension MonthCalendarView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int { days.count }

    func collectionView(_ cv: UICollectionView, cellForItemAt ip: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: "day", for: ip) as! DayCell
        let date = days[ip.item]
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let dotCount = date.flatMap { dots[fmt.string(from: $0)] } ?? 0
        let isToday = date.map { Calendar.current.isDateInToday($0) } ?? false
        let isSelected = date.map { Calendar.current.isDate($0, inSameDayAs: selectedDate) } ?? false
        cell.configure(date: date, dotCount: dotCount, isToday: isToday, isSelected: isSelected)
        return cell
    }

    func collectionView(_ cv: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = max(1, (cv.bounds.width - 12) / 7)
        return CGSize(width: w, height: 40)
    }

    func collectionView(_ cv: UICollectionView, didSelectItemAt ip: IndexPath) {
        guard let date = days[ip.item] else { return }
        selectedDate = date
        cv.reloadData()
        onDaySelected?(date)
    }
}

// MARK: - DayCell
class DayCell: UICollectionViewCell {
    private let numLabel = UILabel()
    private let countBadge = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 10
        layer.cornerCurve = .continuous

        numLabel.font = .systemFont(ofSize: 14, weight: .medium)
        numLabel.textAlignment = .center
        contentView.addSubview(numLabel)

        countBadge.font = .systemFont(ofSize: 9, weight: .bold)
        countBadge.textAlignment = .center
        countBadge.layer.cornerRadius = 8
        countBadge.layer.masksToBounds = true
        contentView.addSubview(countBadge)

        numLabel.translatesAutoresizingMaskIntoConstraints = false
        countBadge.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            numLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            numLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -4),
            countBadge.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            countBadge.topAnchor.constraint(equalTo: numLabel.bottomAnchor, constant: 2),
            countBadge.heightAnchor.constraint(equalToConstant: 14),
            countBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 14),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(date: Date?, dotCount: Int, isToday: Bool, isSelected: Bool) {
        guard let date = date else {
            numLabel.text = ""
            countBadge.text = ""
            countBadge.isHidden = true
            backgroundColor = .clear
            return
        }
        numLabel.text = "\(Calendar.current.component(.day, from: date))"
        countBadge.isHidden = dotCount == 0
        countBadge.text = dotCount > 0 ? "\(dotCount)" : ""

        if isSelected {
            backgroundColor = BarberTheme.gold
            numLabel.textColor = .black
            numLabel.font = .systemFont(ofSize: 14, weight: .bold)
            countBadge.backgroundColor = UIColor.black.withAlphaComponent(0.25)
            countBadge.textColor = .black
        } else if isToday {
            backgroundColor = BarberTheme.gold.withAlphaComponent(0.15)
            numLabel.textColor = BarberTheme.gold
            numLabel.font = .systemFont(ofSize: 14, weight: .bold)
            countBadge.backgroundColor = BarberTheme.gold.withAlphaComponent(0.3)
            countBadge.textColor = BarberTheme.gold
        } else {
            backgroundColor = .clear
            numLabel.textColor = UIColor(white: 0.75, alpha: 1)
            numLabel.font = .systemFont(ofSize: 14, weight: .medium)
            countBadge.backgroundColor = BarberTheme.gold.withAlphaComponent(0.25)
            countBadge.textColor = BarberTheme.gold
        }
    }
}

// MARK: - WeekGridView
class WeekGridView: UIView {
    private let hScroll = UIScrollView()
    private let hourH: CGFloat = 56
    private let startHour = 6
    private let endHour = 24
    private let colW: CGFloat = 120
    private let leftPad: CGFloat = 44

    override init(frame: CGRect) {
        super.init(frame: frame)
        heightAnchor.constraint(equalToConstant: 480).isActive = true
        hScroll.showsHorizontalScrollIndicator = false
        hScroll.showsVerticalScrollIndicator = true
        addSubview(hScroll)
        hScroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hScroll.topAnchor.constraint(equalTo: topAnchor),
            hScroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            hScroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            hScroll.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func setAppointments(_ appointments: [Appointment], weekOf date: Date) {
        hScroll.subviews.forEach { $0.removeFromSuperview() }
        let cal = Calendar.current
        let sun = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) ?? date
        let dayFmt = DateFormatter()
        dayFmt.dateFormat = "EEE\nd"
        dayFmt.locale = Locale(identifier: "pt_BR")

        let totalH = CGFloat(endHour - startHour) * hourH + 36
        let totalW = colW * 7

        let canvas = UIView(frame: CGRect(x: 0, y: 0, width: totalW, height: totalH))
        hScroll.addSubview(canvas)
        hScroll.contentSize = CGSize(width: totalW, height: totalH)

        for d in 0..<7 {
            let day = cal.date(byAdding: .day, value: d, to: sun) ?? sun
            let x = CGFloat(d) * colW
            let isToday = cal.isDateInToday(day)

            let hdr = UILabel()
            hdr.text = dayFmt.string(from: day).uppercased()
            hdr.font = .systemFont(ofSize: 11, weight: isToday ? .bold : .regular)
            hdr.textColor = isToday ? BarberTheme.gold : BarberTheme.textMuted
            hdr.textAlignment = .center
            hdr.numberOfLines = 2
            hdr.frame = CGRect(x: x, y: 0, width: colW, height: 32)
            canvas.addSubview(hdr)

            let sep = UIView()
            sep.backgroundColor = BarberTheme.border
            sep.frame = CGRect(x: x + colW - 0.5, y: 0, width: 0.5, height: totalH)
            canvas.addSubview(sep)

            for h in startHour..<endHour {
                let y = CGFloat(h - startHour) * hourH + 36
                let line = UIView()
                line.backgroundColor = UIColor(white: 1, alpha: 0.04)
                line.frame = CGRect(x: x, y: y, width: colW, height: 0.5)
                canvas.addSubview(line)
            }

            let dayAppts = appointments.filter {
                guard let d2 = ISO8601DateFormatter().date(from: $0.appointmentDate) else { return false }
                return cal.isDate(d2, inSameDayAs: day)
            }
            for appt in dayAppts {
                guard let d2 = ISO8601DateFormatter().date(from: appt.appointmentDate) else { continue }
                let comps = cal.dateComponents([.hour, .minute], from: d2)
                let h = CGFloat((comps.hour ?? 0) - startHour)
                let m = CGFloat(comps.minute ?? 0)
                let y = h * hourH + (m / 60) * hourH + 36
                let dur = CGFloat(appt.service?.durationMinutes ?? 60)
                let bH = max((dur / 60) * hourH - 2, 40)

                let color = BarberTheme.statusColor(appt.status.rawValue)
                let block = UIView()
                block.backgroundColor = color.withAlphaComponent(0.2)
                block.layer.borderColor = color.withAlphaComponent(0.5).cgColor
                block.layer.borderWidth = 1
                block.layer.cornerRadius = 6
                block.frame = CGRect(x: x + 2, y: y, width: colW - 4, height: bH)

                let lbl = UILabel()
                lbl.text = appt.customerName
                lbl.font = .systemFont(ofSize: 10, weight: .semibold)
                lbl.textColor = .white
                lbl.numberOfLines = 2
                lbl.frame = CGRect(x: 4, y: 2, width: colW - 12, height: bH - 4)
                block.addSubview(lbl)
                canvas.addSubview(block)
            }
        }
    }
}

// MARK: - AppointmentsDayListView
class AppointmentsDayListView: UIView {
    private let stackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        stackView.axis = .vertical
        stackView.spacing = 8
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func setAppointments(_ appointments: [Appointment], for date: Date) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let cal = Calendar.current
        let filtered = appointments.filter { appt in
            guard let d = ISO8601DateFormatter().date(from: appt.appointmentDate) else { return false }
            return cal.isDate(d, inSameDayAs: date)
        }
        if filtered.isEmpty {
            let lbl = UILabel()
            lbl.text = "Nenhum agendamento neste dia"
            lbl.font = .systemFont(ofSize: 14)
            lbl.textColor = BarberTheme.textMuted
            stackView.addArrangedSubview(lbl)
        } else {
            for (idx, appt) in filtered.enumerated() {
                let block = AppointmentTimeBlock()
                block.configure(with: appt)
                block.layer.cornerRadius = 10
                block.layer.cornerCurve = .continuous
                block.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true
                block.tag = idx
                let tap = UITapGestureRecognizer(target: self, action: #selector(blockTapped(_:)))
                block.addGestureRecognizer(tap)
                block.isUserInteractionEnabled = true
                stackView.addArrangedSubview(block)
            }
        }
        self.appointments = filtered
        self.date = date
    }

    private var appointments: [Appointment] = []
    private var date = Date()

    @objc private func blockTapped(_ gr: UITapGestureRecognizer) {
        guard let view = gr.view, view.tag < appointments.count,
              let vc = findViewController() as? CalendarViewController else { return }
        let appt = appointments[view.tag]
        let detail = AppointmentDetailViewController(appointment: appt)
        vc.navigationController?.pushViewController(detail, animated: true)
    }
}

// MARK: - DayAppointmentsSheetViewController (sheet que sobe ao tocar no dia no mês)
class DayAppointmentsSheetViewController: UIViewController {
    var onSelectAppointment: ((Appointment) -> Void)?

    private let date: Date
    private let appointments: [Appointment]
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()

    init(date: Date, appointments: [Appointment]) {
        self.date = date
        self.appointments = appointments
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BarberTheme.bg

        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, d 'de' MMMM"
        fmt.locale = Locale(identifier: "pt_BR")
        title = fmt.string(from: date).capitalized

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Fechar", style: .plain, target: self, action: #selector(closeTapped))
        navigationItem.leftBarButtonItem?.tintColor = BarberTheme.gold

        tableView.backgroundColor = .clear
        tableView.separatorColor = BarberTheme.border
        tableView.register(AppointmentTimeBlockCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        emptyLabel.text = "Nenhum agendamento neste dia"
        emptyLabel.textColor = BarberTheme.textMuted
        emptyLabel.font = .systemFont(ofSize: 15)
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = !appointments.isEmpty
        view.addSubview(emptyLabel)
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

extension DayAppointmentsSheetViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        appointments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! AppointmentTimeBlockCell
        cell.configure(with: appointments[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        onSelectAppointment?(appointments[indexPath.row])
    }
}

// Célula que embute um AppointmentTimeBlock para usar na tabela do sheet
class AppointmentTimeBlockCell: UITableViewCell {
    private let block = AppointmentTimeBlock()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(block)
        block.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            block.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            block.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            block.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            block.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with appt: Appointment) {
        block.configure(with: appt)
    }
}

// MARK: - BarberFilterBar
class BarberFilterBar: UIView {
    var onFilter: ((String?) -> Void)?
    private let scrollView = UIScrollView()
    private var barbers: [BarberInfo] = []
    private var barberButtons: [(id: String?, button: UIButton)] = []
    private var selectedBarberId: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        scrollView.showsHorizontalScrollIndicator = false
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        loadBarbers()
    }
    required init?(coder: NSCoder) { fatalError() }

    func setSelectedBarberId(_ id: String?) {
        selectedBarberId = id
        updateButtonsAppearance()
    }

    private func loadBarbers() {
        ApiService.shared.getBarbers { [weak self] result in
            if case .success(let list) = result {
                DispatchQueue.main.async { self?.buildButtons(list) }
            }
        }
    }

    private func updateButtonsAppearance() {
        for (id, btn) in barberButtons {
            let isSelected = (id == selectedBarberId)
            btn.configuration?.baseForegroundColor = isSelected ? .black : BarberTheme.gold
            btn.backgroundColor = isSelected ? BarberTheme.gold : .clear
            btn.layer.borderColor = (isSelected ? BarberTheme.gold : BarberTheme.goldDim).cgColor
        }
    }

    private func buildButtons(_ barbers: [BarberInfo]) {
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        self.barbers = barbers
        barberButtons.removeAll()

        var x: CGFloat = 0
        let allItems: [(String, String?)] = [("Todos", nil)] + barbers.map { ($0.name, $0.id) }
        for (name, id) in allItems {
            let btn = UIButton(type: .system)
            var config = UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 14, bottom: 4, trailing: 14)
            config.attributedTitle = AttributedString(name, attributes: AttributeContainer([.font: UIFont.systemFont(ofSize: 13, weight: .medium)]))
            config.baseForegroundColor = (id == selectedBarberId) ? .black : BarberTheme.gold
            btn.configuration = config
            btn.backgroundColor = (id == selectedBarberId) ? BarberTheme.gold : .clear
            btn.layer.borderWidth = 1
            btn.layer.borderColor = (id == selectedBarberId ? BarberTheme.gold : BarberTheme.goldDim).cgColor
            btn.layer.cornerRadius = 14
            btn.sizeToFit()
            let w = btn.bounds.width + 28
            btn.frame = CGRect(x: x, y: 2, width: w, height: 30)
            btn.addAction(UIAction { [weak self] _ in
                self?.selectedBarberId = id
                self?.updateButtonsAppearance()
                self?.onFilter?(id)
            }, for: .touchUpInside)
            scrollView.addSubview(btn)
            barberButtons.append((id, btn))
            x += w + 8
        }
        scrollView.contentSize = CGSize(width: x, height: 34)
    }
}

// MARK: - UIView + findViewController
extension UIView {
    func findViewController() -> UIViewController? {
        var r: UIResponder? = self
        while let next = r?.next {
            if let vc = next as? UIViewController { return vc }
            r = next
        }
        return nil
    }
}
