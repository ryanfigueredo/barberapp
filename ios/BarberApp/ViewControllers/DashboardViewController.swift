//
//  DashboardViewController.swift
//  BarberApp
//
//  Visão analítica: agendamentos, faturamento, próximos do dia.
//

import UIKit

final class DashboardViewController: UIViewController {

    private var stats: DashboardStats?
    private let scrollView = UIScrollView()
    private let stackView = UIStackView()
    private let refreshControl = UIRefreshControl()

    private let cardsRow1 = UIStackView()
    private let cardsRow2 = UIStackView()
    private let upcomingSection = UIStackView()
    private let upcomingTitle = UILabel()
    private let upcomingList = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BarberTheme.bg
        title = "Visão"
        navigationController?.navigationBar.prefersLargeTitles = true
        refreshControl.tintColor = BarberTheme.gold
        refreshControl.addTarget(self, action: #selector(loadStats), for: .valueChanged)
        setupLayout()
        loadStats()
    }

    private func setupLayout() {
        scrollView.showsVerticalScrollIndicator = false
        scrollView.refreshControl = refreshControl
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        cardsRow1.axis = .horizontal
        cardsRow1.distribution = .fillEqually
        cardsRow1.spacing = 12
        cardsRow2.axis = .horizontal
        cardsRow2.distribution = .fillEqually
        cardsRow2.spacing = 12

        stackView.addArrangedSubview(cardsRow1)
        stackView.addArrangedSubview(cardsRow2)

        upcomingTitle.text = "Próximos hoje"
        upcomingTitle.font = .systemFont(ofSize: 17, weight: .bold)
        upcomingTitle.textColor = BarberTheme.gold
        stackView.addArrangedSubview(upcomingTitle)
        upcomingList.axis = .vertical
        upcomingList.spacing = 8
        stackView.addArrangedSubview(upcomingList)
    }

    @objc private func loadStats() {
        ApiService.shared.fetch("/api/admin/stats") { [weak self] (result: Result<DashboardStats, Error>) in
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
                switch result {
                case .success(let s):
                    self?.stats = s
                    self?.reloadUI()
                case .failure:
                    self?.reloadUI()
                }
            }
        }
    }

    private func reloadUI() {
        cardsRow1.arrangedSubviews.forEach { $0.removeFromSuperview() }
        cardsRow2.arrangedSubviews.forEach { $0.removeFromSuperview() }
        upcomingList.arrangedSubviews.forEach { $0.removeFromSuperview() }

        guard let s = stats else {
            cardsRow1.addArrangedSubview(card(title: "Hoje", value: "–", subtitle: "agendamentos"))
            cardsRow1.addArrangedSubview(card(title: "Semana", value: "–", subtitle: "agendamentos"))
            cardsRow2.addArrangedSubview(card(title: "Barbeiros", value: "–", subtitle: "ativos"))
            cardsRow2.addArrangedSubview(card(title: "Faturamento hoje", value: "–", subtitle: "R$"))
            cardsRow2.addArrangedSubview(card(title: "Faturamento semana", value: "–", subtitle: "R$"))
            return
        }

        cardsRow1.addArrangedSubview(card(title: "Hoje", value: "\(s.today)", subtitle: "agendamentos"))
        cardsRow1.addArrangedSubview(card(title: "Semana", value: "\(s.week)", subtitle: "agendamentos"))
        cardsRow2.addArrangedSubview(card(title: "Barbeiros", value: "\(s.barbers)", subtitle: "ativos"))
        let revToday = s.revenue_today ?? 0
        let revWeek = s.revenue_week ?? 0
        cardsRow2.addArrangedSubview(card(title: "Faturamento hoje", value: formatMoney(revToday), subtitle: "concluídos"))
        cardsRow2.addArrangedSubview(card(title: "Faturamento semana", value: formatMoney(revWeek), subtitle: "concluídos"))

        if s.upcoming_today.isEmpty {
            let lbl = UILabel()
            lbl.text = "Nenhum agendamento restante hoje"
            lbl.font = .systemFont(ofSize: 14)
            lbl.textColor = BarberTheme.textMuted
            upcomingList.addArrangedSubview(lbl)
        } else {
            let fmt = DateFormatter()
            fmt.dateFormat = "HH:mm"
            for item in s.upcoming_today {
                let date = ISO8601DateFormatter().date(from: item.appointment_date) ?? Date()
                let timeStr = fmt.string(from: date)
                let block = upcomingRow(time: timeStr, name: item.customer_name, service: item.service?.name ?? "–")
                upcomingList.addArrangedSubview(block)
            }
        }
    }

    private func card(title: String, value: String, subtitle: String) -> UIView {
        let wrap = UIView()
        wrap.backgroundColor = BarberTheme.surface
        wrap.layer.cornerRadius = 14
        wrap.layer.cornerCurve = .continuous
        wrap.layer.borderWidth = 1
        wrap.layer.borderColor = BarberTheme.border.cgColor

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        titleLabel.textColor = BarberTheme.textMuted
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 22, weight: .bold)
        valueLabel.textColor = BarberTheme.gold
        let subLabel = UILabel()
        subLabel.text = subtitle
        subLabel.font = .systemFont(ofSize: 11)
        subLabel.textColor = BarberTheme.textMuted

        let inner = UIStackView(arrangedSubviews: [titleLabel, valueLabel, subLabel])
        inner.axis = .vertical
        inner.spacing = 4
        inner.alignment = .leading
        wrap.addSubview(inner)
        inner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 12),
            inner.leadingAnchor.constraint(equalTo: wrap.leadingAnchor, constant: 12),
            inner.trailingAnchor.constraint(equalTo: wrap.trailingAnchor, constant: -12),
            inner.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -12),
        ])
        wrap.heightAnchor.constraint(greaterThanOrEqualToConstant: 88).isActive = true
        return wrap
    }

    private func upcomingRow(time: String, name: String, service: String) -> UIView {
        let row = UIView()
        row.backgroundColor = BarberTheme.surface
        row.layer.cornerRadius = 10
        row.layer.cornerCurve = .continuous
        row.layer.borderWidth = 1
        row.layer.borderColor = BarberTheme.border.cgColor

        let timeLbl = UILabel()
        timeLbl.text = time
        timeLbl.font = .monospacedSystemFont(ofSize: 13, weight: .semibold)
        timeLbl.textColor = BarberTheme.gold
        let nameLbl = UILabel()
        nameLbl.text = name
        nameLbl.font = .systemFont(ofSize: 15, weight: .medium)
        nameLbl.textColor = BarberTheme.textPrimary
        let serviceLbl = UILabel()
        serviceLbl.text = service
        serviceLbl.font = .systemFont(ofSize: 12)
        serviceLbl.textColor = BarberTheme.textMuted

        let right = UIStackView(arrangedSubviews: [nameLbl, serviceLbl])
        right.axis = .vertical
        right.spacing = 2
        right.alignment = .leading
        let h = UIStackView(arrangedSubviews: [timeLbl, right])
        h.axis = .horizontal
        h.spacing = 12
        h.alignment = .center
        row.addSubview(h)
        h.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            h.topAnchor.constraint(equalTo: row.topAnchor, constant: 10),
            h.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 12),
            h.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -12),
            h.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -10),
        ])
        timeLbl.setContentHuggingPriority(.required, for: .horizontal)
        row.heightAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
        return row
    }

    private func formatMoney(_ value: Double) -> String {
        if value == 0 { return "R$ 0" }
        return String(format: "R$ %.0f", value)
    }
}
