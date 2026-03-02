//
//  BarbersViewController.swift
//  BarberApp
//
//  Lista de barbeiros da barbearia
//

import UIKit

class BarbersViewController: UIViewController {

    private var barbers: [BarberInfo] = []
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let refreshControl = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Barbeiros"
        view.backgroundColor = BarberAppTheme.background
        navigationController?.navigationBar.prefersLargeTitles = true
        setupTableView()
        loadBarbers()
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorColor = BarberAppTheme.border
        tableView.register(BarberRowCell.self, forCellReuseIdentifier: "cell")
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

        emptyLabel.text = "Nenhum barbeiro cadastrado"
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

    private func loadBarbers() {
        Task {
            do {
                let list = try await ApiService.shared.getBarbers()
                await MainActor.run {
                    barbers = list
                    tableView.reloadData()
                    emptyLabel.isHidden = !list.isEmpty
                    refreshControl.endRefreshing()
                }
            } catch {
                await MainActor.run {
                    barbers = []
                    tableView.reloadData()
                    emptyLabel.isHidden = false
                    refreshControl.endRefreshing()
                }
            }
        }
    }

    @objc private func handleRefresh() {
        loadBarbers()
    }
}

extension BarbersViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        barbers.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! BarberRowCell
        cell.configure(with: barbers[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

private final class BarberRowCell: UITableViewCell {
    private let avatarView = UIView()
    private let avatarLabel = UILabel()
    private let nameLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        avatarView.backgroundColor = BarberAppTheme.card
        avatarView.layer.cornerRadius = 24
        avatarView.layer.borderWidth = 1
        avatarView.layer.borderColor = BarberAppTheme.gold.withAlphaComponent(0.3).cgColor
        contentView.addSubview(avatarView)
        avatarLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        avatarLabel.textColor = BarberAppTheme.gold
        avatarLabel.textAlignment = .center
        avatarView.addSubview(avatarLabel)
        nameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        nameLabel.textColor = BarberAppTheme.textPrimary
        contentView.addSubview(nameLabel)
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 48),
            avatarView.heightAnchor.constraint(equalToConstant: 48),
            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 14),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with b: BarberInfo) {
        nameLabel.text = b.name
        avatarLabel.text = String(b.name.prefix(1)).uppercased()
    }
}
