//
//  SettingsViewController.swift
//  BarberApp
//

import UIKit

struct SettingsRow {
    let icon: String
    let title: String
    let detail: String?
    let action: (() -> Void)?
}

struct SettingsSection {
    let title: String
    let rows: [SettingsRow]
}

class SettingsViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var sections: [SettingsSection] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Configurações"
        view.backgroundColor = BarberTheme.bg
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSelf))
        navigationItem.leftBarButtonItem?.tintColor = BarberTheme.gold

        buildSections()
        setupTableView()
        setupLogoutButton()
    }

    private func buildSections() {
        sections = [
            SettingsSection(title: "Barbearia", rows: [
                SettingsRow(icon: "building.2.fill", title: "Nome da barbearia", detail: nil, action: { [weak self] in self?.editField("name", title: "Nome") }),
                SettingsRow(icon: "mappin.circle.fill", title: "Endereço", detail: nil, action: { [weak self] in self?.editField("address", title: "Endereço") }),
                SettingsRow(icon: "clock.fill", title: "Horário de abertura", detail: nil, action: { [weak self] in self?.editHours() }),
                SettingsRow(icon: "photo.fill", title: "Logo da barbearia", detail: nil, action: { [weak self] in self?.pickLogo() }),
            ]),
            SettingsSection(title: "WhatsApp", rows: [
                SettingsRow(icon: "phone.fill", title: "Número WhatsApp", detail: nil, action: nil),
                SettingsRow(icon: "message.badge.waveform.fill", title: "Status do Bot", detail: nil, action: nil),
                SettingsRow(icon: "gearshape.fill", title: "Configurar Meta API", detail: nil, action: { [weak self] in self?.openBotSetup() }),
            ]),
            SettingsSection(title: "Agendamento", rows: [
                SettingsRow(icon: "timer", title: "Duração padrão do slot", detail: "60 min", action: nil),
                SettingsRow(icon: "bell.fill", title: "Lembretes automáticos", detail: "Ativo", action: nil),
            ]),
            SettingsSection(title: "Conta", rows: [
                SettingsRow(icon: "person.fill", title: "Meu perfil", detail: nil, action: nil),
                SettingsRow(icon: "lock.fill", title: "Alterar senha", detail: nil, action: { [weak self] in self?.changePassword() }),
                SettingsRow(icon: "info.circle.fill", title: "Versão do app", detail: "1.0.0", action: nil),
            ]),
        ]
    }

    private func setupTableView() {
        tableView.backgroundColor = BarberTheme.bg
        tableView.register(SettingsCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 90, right: 0)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        let header = TenantHeaderView()
        header.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 140)
        tableView.tableHeaderView = header
        ApiService.shared.getTenantProfile { result in
            DispatchQueue.main.async {
                if case .success(let p) = result { header.configure(profile: p) }
            }
        }
    }

    private func setupLogoutButton() {
        let logoutBtn = UIButton(type: .system)
        logoutBtn.setTitle("Sair da conta", for: .normal)
        logoutBtn.setTitleColor(BarberTheme.danger, for: .normal)
        logoutBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        logoutBtn.backgroundColor = BarberTheme.danger.withAlphaComponent(0.10)
        logoutBtn.layer.cornerRadius = 12
        logoutBtn.layer.borderWidth = 1
        logoutBtn.layer.borderColor = BarberTheme.danger.withAlphaComponent(0.25).cgColor
        logoutBtn.addTarget(self, action: #selector(logout), for: .touchUpInside)

        let footer = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 80))
        footer.addSubview(logoutBtn)
        logoutBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            logoutBtn.leadingAnchor.constraint(equalTo: footer.leadingAnchor, constant: 16),
            logoutBtn.trailingAnchor.constraint(equalTo: footer.trailingAnchor, constant: -16),
            logoutBtn.topAnchor.constraint(equalTo: footer.topAnchor, constant: 16),
            logoutBtn.heightAnchor.constraint(equalToConstant: 48),
        ])
        tableView.tableFooterView = footer
    }

    private func editField(_ key: String, title: String) {
        let alert = UIAlertController(title: "Editar \(title)", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = title }
        alert.addAction(UIAlertAction(title: "Salvar", style: .default) { [weak alert] _ in
            guard let value = alert?.textFields?.first?.text else { return }
            ApiService.shared.updateTenantProfile([key: value]) { _ in }
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    private func editHours() {
        let vc = StoreHoursViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    private func pickLogo() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    private func openBotSetup() {
        let vc = BotSetupViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    private func changePassword() {
        let vc = ChangePasswordViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }

    @objc private func logout() {
        let alert = UIAlertController(title: "Sair", message: "Deseja sair da conta?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Sair", style: .destructive) { [weak self] _ in
            AuthService.shared.logout()
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else { return }
            window.rootViewController = LoginViewController()
            window.makeKeyAndVisible()
        })
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tv: UITableView) -> Int { sections.count }

    func tableView(_ tv: UITableView, numberOfRowsInSection s: Int) -> Int { sections[s].rows.count }

    func tableView(_ tv: UITableView, titleForHeaderInSection s: Int) -> String? { sections[s].title }

    func tableView(_ tv: UITableView, cellForRowAt ip: IndexPath) -> UITableViewCell {
        let cell = tv.dequeueReusableCell(withIdentifier: "cell", for: ip) as! SettingsCell
        cell.configure(with: sections[ip.section].rows[ip.row])
        return cell
    }

    func tableView(_ tv: UITableView, didSelectRowAt ip: IndexPath) {
        tv.deselectRow(at: ip, animated: true)
        sections[ip.section].rows[ip.row].action?()
    }
}

extension SettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        dismiss(animated: true)
    }
}

// MARK: - SettingsCell
class SettingsCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        backgroundColor = BarberTheme.surface
        textLabel?.textColor = BarberTheme.textPrimary
        detailTextLabel?.textColor = BarberTheme.textMuted
        imageView?.tintColor = BarberTheme.gold
        accessoryType = .disclosureIndicator
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with row: SettingsRow) {
        textLabel?.text = row.title
        detailTextLabel?.text = row.detail
        let cfg = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        imageView?.image = UIImage(systemName: row.icon, withConfiguration: cfg)
        accessoryType = row.action != nil ? .disclosureIndicator : .none
    }
}

// MARK: - TenantHeaderView
class TenantHeaderView: UIView {

    private let avatarView = UIView()
    private let avatarLabel = UILabel()
    private let nameLabel = UILabel()
    private let slugLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        avatarView.backgroundColor = BarberTheme.gold.withAlphaComponent(0.15)
        avatarView.layer.cornerRadius = 36
        avatarView.layer.borderWidth = 2
        avatarView.layer.borderColor = BarberTheme.goldDim.cgColor
        addSubview(avatarView)

        avatarLabel.font = .systemFont(ofSize: 28, weight: .bold)
        avatarLabel.textColor = BarberTheme.gold
        avatarLabel.textAlignment = .center
        avatarView.addSubview(avatarLabel)

        nameLabel.font = .systemFont(ofSize: 20, weight: .bold)
        nameLabel.textColor = BarberTheme.textPrimary
        addSubview(nameLabel)

        slugLabel.font = .systemFont(ofSize: 13)
        slugLabel.textColor = BarberTheme.textSecond
        addSubview(slugLabel)

        [avatarView, avatarLabel, nameLabel, slugLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            avatarView.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 72),
            avatarView.heightAnchor.constraint(equalToConstant: 72),
            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: 10),
            slugLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            slugLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
        ])
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(profile: TenantProfile) {
        nameLabel.text = profile.name
        slugLabel.text = "@\(profile.slug ?? "")"
        avatarLabel.text = String(profile.name.prefix(1)).uppercased()
    }
}
