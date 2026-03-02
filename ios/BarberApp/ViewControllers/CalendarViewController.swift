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

    private let scrollView = UIScrollView()
    private let modeSegment = UISegmentedControl(items: ["Dia", "Semana", "Mês"])
    private let monthHeaderView = MonthCalendarView()
    private let dayTimelineView = DayTimelineView()
    private let weekGridView = WeekGridView()
    private let filterBar = BarberFilterBar()
    private let refreshControl = UIRefreshControl()
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
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "+ Novo", style: .plain, target: self, action: #selector(newAppointment)),
            UIBarButtonItem(title: "Hoje", style: .plain, target: self, action: #selector(goToToday)),
        ]
        navigationItem.rightBarButtonItems?.forEach { $0.tintColor = BarberTheme.gold }
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
            self?.applyFilter()
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

        contentStack.addArrangedSubview(monthHeaderView)
        contentStack.addArrangedSubview(dayTimelineView)
        contentStack.addArrangedSubview(weekGridView)

        contentStack.addArrangedSubview(selectedDateLabel)

        contentStack.addArrangedSubview(appointmentsListView)

        monthHeaderView.onDaySelected = { [weak self] date in
            self?.selectedDate = date
            self?.updateSelectedDateLabel()
            self?.loadAppointments()
        }
        monthHeaderView.onSwipeMonth = { [weak self] direction in
            guard let self else { return }
            if let d = Calendar.current.date(byAdding: .month, value: direction, to: selectedDate) {
                selectedDate = d
                monthHeaderView.setCurrentDate(d)
                loadMonthDots()
            }
        }
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
            self.monthHeaderView.isHidden = newMode != .month
            self.dayTimelineView.isHidden = newMode != .day
            self.weekGridView.isHidden = newMode != .week
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
        let path: String
        switch mode {
        case .day, .month:
            path = "/api/app/appointments?date=\(dateStr)"
        case .week:
            let cal = Calendar.current
            let sun = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate)) ?? selectedDate
            let sat = cal.date(byAdding: .day, value: 6, to: sun) ?? sun
            path = "/api/app/appointments?start=\(dateFormatter.string(from: sun))&end=\(dateFormatter.string(from: sat))"
        }

        ApiService.shared.fetch(path) { [weak self] (result: Result<AppointmentsResponse, Error>) in
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
                if case .success(let resp) = result {
                    self?.allAppointments = resp.appointments
                    self?.applyFilter()
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
            monthHeaderView.setSelectedDate(selectedDate)
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
        ApiService.shared.fetch("/api/app/appointments/month?month=\(month)") { [weak self] (result: Result<MonthAppointmentsResponse, Error>) in
            DispatchQueue.main.async {
                if case .success(let resp) = result {
                    var dots: [String: Int] = [:]
                    resp.days_with_appointments?.forEach { day, info in
                        dots[day] = info.count ?? 0
                    }
                    self?.monthDots = dots
                    self?.monthHeaderView.setDots(dots)
                    self?.monthHeaderView.setCurrentDate(self?.selectedDate ?? Date())
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
        loadAppointments()
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
        let contentWidth = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width
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

    private let dayNames = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
    private var days: [Date?] = []
    private var collectionHeightConstraint: NSLayoutConstraint?

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

        let headerStack = UIStackView()
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
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        collectionView.backgroundColor = .clear
        collectionView.isScrollEnabled = false
        collectionView.register(DayCell.self, forCellWithReuseIdentifier: "day")
        collectionView.delegate = self
        collectionView.dataSource = self
        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerStack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            headerStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            headerStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            headerStack.heightAnchor.constraint(equalToConstant: 20),
            collectionView.topAnchor.constraint(equalTo: headerStack.bottomAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
        ])
        let hc = collectionView.heightAnchor.constraint(equalToConstant: 240)
        collectionHeightConstraint = hc
        hc.isActive = true

        generateDays()
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
        generateDays()
        collectionView.reloadData()
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
        let weeks = Int(ceil(Double(days.count) / 7.0))
        let itemH: CGFloat = 38
        let gap: CGFloat = 2
        let newH = CGFloat(weeks) * itemH + CGFloat(max(0, weeks - 1)) * gap
        collectionHeightConstraint?.constant = newH
        UIView.animate(withDuration: 0.2) { self.layoutIfNeeded() }
    }

    func setDots(_ dots: [String: Int]) {
        self.dots = dots
        collectionView.reloadData()
    }

    func setCurrentDate(_ date: Date) {
        currentDate = date
        generateDays()
        collectionView.reloadData()
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
        let w = (cv.bounds.width - 12) / 7
        return CGSize(width: w, height: 38)
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
    private let dotsStack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 10
        layer.cornerCurve = .continuous

        numLabel.font = .systemFont(ofSize: 14, weight: .medium)
        numLabel.textAlignment = .center
        contentView.addSubview(numLabel)

        dotsStack.axis = .horizontal
        dotsStack.spacing = 2
        dotsStack.alignment = .center
        contentView.addSubview(dotsStack)

        numLabel.translatesAutoresizingMaskIntoConstraints = false
        dotsStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            numLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            numLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: -4),
            dotsStack.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dotsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -3),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(date: Date?, dotCount: Int, isToday: Bool, isSelected: Bool) {
        guard let date = date else {
            numLabel.text = ""
            dotsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            backgroundColor = .clear
            return
        }
        numLabel.text = "\(Calendar.current.component(.day, from: date))"
        if isSelected {
            backgroundColor = BarberTheme.gold
            numLabel.textColor = .black
            numLabel.font = .systemFont(ofSize: 14, weight: .bold)
        } else if isToday {
            backgroundColor = BarberTheme.gold.withAlphaComponent(0.15)
            numLabel.textColor = BarberTheme.gold
            numLabel.font = .systemFont(ofSize: 14, weight: .bold)
        } else {
            backgroundColor = .clear
            numLabel.textColor = UIColor(white: 0.75, alpha: 1)
            numLabel.font = .systemFont(ofSize: 14, weight: .medium)
        }

        dotsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let count = min(dotCount, 3)
        for _ in 0..<count {
            let dot = UIView()
            dot.backgroundColor = isSelected ? UIColor.black.withAlphaComponent(0.5) : BarberTheme.gold
            dot.layer.cornerRadius = 2
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.widthAnchor.constraint(equalToConstant: 4).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 4).isActive = true
            dotsStack.addArrangedSubview(dot)
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
            for appt in filtered {
                let block = AppointmentTimeBlock()
                block.configure(with: appt)
                block.layer.cornerRadius = 10
                block.layer.cornerCurve = .continuous
                block.heightAnchor.constraint(greaterThanOrEqualToConstant: 56).isActive = true
                stackView.addArrangedSubview(block)
            }
        }
    }
}

// MARK: - BarberFilterBar
class BarberFilterBar: UIView {
    var onFilter: ((String?) -> Void)?
    private let scrollView = UIScrollView()
    private var barbers: [BarberInfo] = []

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

    private func loadBarbers() {
        ApiService.shared.getBarbers { [weak self] result in
            if case .success(let list) = result {
                DispatchQueue.main.async { self?.buildButtons(list) }
            }
        }
    }

    private func buildButtons(_ barbers: [BarberInfo]) {
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        self.barbers = barbers

        var x: CGFloat = 0
        let allItems: [(String, String?)] = [("Todos", nil)] + barbers.map { ($0.name, $0.id) }
        for (name, id) in allItems {
            let btn = UIButton(type: .system)
            btn.setTitle(name, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            btn.setTitleColor(BarberTheme.gold, for: .normal)
            btn.layer.borderWidth = 1
            btn.layer.borderColor = BarberTheme.goldDim.cgColor
            btn.layer.cornerRadius = 14
            btn.contentEdgeInsets = UIEdgeInsets(top: 4, left: 14, bottom: 4, right: 14)
            btn.sizeToFit()
            let w = btn.bounds.width + 28
            btn.frame = CGRect(x: x, y: 2, width: w, height: 30)
            btn.addAction(UIAction { [weak self] _ in self?.onFilter?(id) }, for: .touchUpInside)
            scrollView.addSubview(btn)
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
