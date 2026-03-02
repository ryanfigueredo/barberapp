//
//  MoreViewController.swift
//  BarberApp
//
//  Aba "Mais": Serviços, Barbeiros (e link para Configurações).
//

import UIKit

final class MoreViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private struct Row {
        let icon: String
        let title: String
        let action: () -> Void
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Mais"
        view.backgroundColor = BarberTheme.bg
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gearshape.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)),
            style: .plain, target: self, action: #selector(openSettings)
        )
        navigationItem.rightBarButtonItem?.tintColor = BarberTheme.gold
        setupTableView()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private func setupTableView() {
        tableView.backgroundColor = BarberTheme.bg
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private var rows: [Row] {
        [
            Row(icon: "scissors", title: "Serviços") { [weak self] in
                self?.navigationController?.pushViewController(ServicesViewController(), animated: true)
            },
            Row(icon: "person.2.fill", title: "Barbeiros") { [weak self] in
                self?.navigationController?.pushViewController(BarbersViewController(), animated: true)
            },
        ]
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
}

extension MoreViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { rows.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let row = rows[indexPath.row]
        cell.textLabel?.text = row.title
        cell.textLabel?.textColor = BarberTheme.textPrimary
        cell.backgroundColor = BarberTheme.surface
        cell.accessoryType = .disclosureIndicator
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        cell.imageView?.image = UIImage(systemName: row.icon, withConfiguration: config)
        cell.imageView?.tintColor = BarberTheme.gold
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        rows[indexPath.row].action()
    }
}
