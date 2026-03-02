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

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

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
        picker.mediaTypes = ["public.image"]
        present(picker, animated: true)
    }

    private func uploadLogo(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        let contentType = "image/jpeg"

        let loading = UIAlertController(title: "Enviando logo…", message: nil, preferredStyle: .alert)
        present(loading, animated: true)

        ApiService.shared.requestLogoUploadURL(contentType: contentType) { [weak self] result in
            switch result {
            case .success(let response):
                ApiService.shared.uploadImageToURL(response.uploadUrl, imageData: data, contentType: contentType) { uploadResult in
                    DispatchQueue.main.async {
                        loading.dismiss(animated: true)
                        switch uploadResult {
                        case .success:
                            ApiService.shared.updateTenantProfile(["logo_url": response.publicUrl]) { [weak self] updateResult in
                                DispatchQueue.main.async {
                                    switch updateResult {
                                    case .success:
                                        self?.reloadProfileHeader()
                                        let ok = UIAlertController(title: "Logo atualizada", message: "A logo da barbearia foi salva.", preferredStyle: .alert)
                                        ok.addAction(UIAlertAction(title: "OK", style: .default))
                                        self?.present(ok, animated: true)
                                    case .failure(let err):
                                        self?.showError("Não foi possível salvar a logo: \(err.localizedDescription)")
                                    }
                                }
                            }
                        case .failure(let err):
                            self?.showError("Falha no upload: \(err.localizedDescription)")
                        }
                    }
                }
            case .failure(let err):
                DispatchQueue.main.async {
                    loading.dismiss(animated: true)
                    self?.showError("Não foi possível obter a URL de upload. Configure AWS no servidor.\n\(err.localizedDescription)")
                }
            }
        }
    }

    private func reloadProfileHeader() {
        ApiService.shared.getTenantProfile { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let p) = result, let header = self?.tableView.tableHeaderView as? TenantHeaderView {
                    header.configure(profile: p)
                }
            }
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Erro", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
        alert.addAction(UIAlertAction(title: "Sair", style: .destructive) { _ in
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
        picker.dismiss(animated: true)
        guard let image = info[.originalImage] as? UIImage else { return }
        uploadLogo(image)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
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
    private let avatarImageView = UIImageView()
    private let avatarLabel = UILabel()
    private let nameLabel = UILabel()
    private let slugLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        avatarView.backgroundColor = BarberTheme.gold.withAlphaComponent(0.15)
        avatarView.layer.cornerRadius = 36
        avatarView.layer.borderWidth = 2
        avatarView.layer.borderColor = BarberTheme.goldDim.cgColor
        avatarView.clipsToBounds = true
        addSubview(avatarView)

        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.isHidden = true
        avatarView.addSubview(avatarImageView)

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

        [avatarView, avatarImageView, avatarLabel, nameLabel, slugLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            avatarView.centerYAnchor.constraint(equalTo: centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 72),
            avatarView.heightAnchor.constraint(equalToConstant: 72),
            avatarImageView.topAnchor.constraint(equalTo: avatarView.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarView.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor),
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

        if let urlString = profile.logo_url, let url = URL(string: urlString) {
            avatarLabel.isHidden = true
            avatarImageView.isHidden = false
            loadImage(from: url)
        } else {
            avatarImageView.isHidden = true
            avatarImageView.image = nil
            avatarLabel.isHidden = false
            avatarLabel.text = String(profile.name.prefix(1)).uppercased()
        }
    }

    private func loadImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.avatarImageView.image = image
            }
        }.resume()
    }
}
