//
//  ServicesViewController.swift
//  BarberApp
//
//  Lista de serviços da barbearia
//

import UIKit

class ServicesViewController: UIViewController {

    private var services: [ServiceInfo] = []
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let refreshControl = UIRefreshControl()
    private let priceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.locale = Locale(identifier: "pt_BR")
        return f
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Serviços"
        view.backgroundColor = BarberAppTheme.background
        navigationController?.navigationBar.prefersLargeTitles = true
        setupTableView()
        loadServices()
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorColor = BarberAppTheme.border
        tableView.register(ServiceRowCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 72
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

        emptyLabel.text = "Nenhum serviço cadastrado"
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

    private func loadServices() {
        Task {
            do {
                let list = try await ApiService.shared.getServices()
                await MainActor.run {
                    services = list
                    tableView.reloadData()
                    emptyLabel.isHidden = !list.isEmpty
                    refreshControl.endRefreshing()
                }
            } catch {
                await MainActor.run {
                    services = []
                    tableView.reloadData()
                    emptyLabel.isHidden = false
                    refreshControl.endRefreshing()
                }
            }
        }
    }

    @objc private func handleRefresh() {
        loadServices()
    }
}

extension ServicesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        services.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ServiceRowCell
        cell.configure(with: services[indexPath.row], priceFormatter: priceFormatter)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

private final class ServiceRowCell: UITableViewCell {
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let detailLabel = UILabel()
    private let priceLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        iconView.image = UIImage(systemName: BarberDesign.TabIcon.services, withConfiguration: config)
        iconView.tintColor = BarberAppTheme.gold
        iconView.contentMode = .scaleAspectFit
        contentView.addSubview(iconView)
        nameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = BarberAppTheme.textPrimary
        contentView.addSubview(nameLabel)
        detailLabel.font = .systemFont(ofSize: 13)
        detailLabel.textColor = BarberAppTheme.textSecondary
        contentView.addSubview(detailLabel)
        priceLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        priceLabel.textColor = BarberAppTheme.gold
        contentView.addSubview(priceLabel)
        iconView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        detailLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 14),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            detailLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            detailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            priceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            priceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with s: ServiceInfo, priceFormatter: NumberFormatter) {
        nameLabel.text = s.name
        detailLabel.text = "\(s.durationMinutes) min"
        priceLabel.text = priceFormatter.string(from: NSNumber(value: s.price))
    }
}
