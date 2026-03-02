//
//  LoginViewController.swift
//  BarberApp
//
//  Login por usuário/email + senha. A API key fica vinculada ao login (retornada pelo backend).
//  Admin vê tudo da barbearia; barbeiro vê só os próprios dados.
//

import UIKit

class LoginViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let usernameField = UITextField()
    private let passwordField = UITextField()
    private let loginButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let glassCard = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BarberAppTheme.background
        setupUI()
    }

    private func setupUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .onDrag
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        titleLabel.text = "BarberApp"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textColor = BarberAppTheme.gold
        titleLabel.textAlignment = .center
        contentStack.addArrangedSubview(titleLabel)

        subtitleLabel.text = "Entre com seu usuário da barbearia"
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = BarberAppTheme.textTertiary
        subtitleLabel.textAlignment = .center
        contentStack.addArrangedSubview(subtitleLabel)

        glassCard.backgroundColor = BarberAppTheme.card
        glassCard.layer.cornerRadius = 16
        glassCard.layer.borderWidth = 1
        glassCard.layer.borderColor = BarberAppTheme.gold.withAlphaComponent(0.25).cgColor
        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 16
        cardStack.isLayoutMarginsRelativeArrangement = true
        cardStack.layoutMargins = UIEdgeInsets(top: 24, left: 20, bottom: 24, right: 20)

        usernameField.placeholder = "Usuário ou e-mail"
        styleField(usernameField)
        usernameField.keyboardType = .emailAddress
        usernameField.autocapitalizationType = .none
        usernameField.autocorrectionType = .no
        cardStack.addArrangedSubview(usernameField)

        passwordField.placeholder = "Senha"
        styleField(passwordField)
        passwordField.isSecureTextEntry = true
        cardStack.addArrangedSubview(passwordField)

        loginButton.setTitle("Entrar", for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        loginButton.setTitleColor(BarberAppTheme.background, for: .normal)
        loginButton.backgroundColor = BarberAppTheme.gold
        loginButton.layer.cornerRadius = 12
        loginButton.addTarget(self, action: #selector(doLogin), for: .touchUpInside)
        cardStack.addArrangedSubview(loginButton)

        loadingIndicator.color = BarberAppTheme.background
        loadingIndicator.hidesWhenStopped = true
        cardStack.addArrangedSubview(loadingIndicator)

        glassCard.addSubview(cardStack)
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: glassCard.topAnchor),
            cardStack.leadingAnchor.constraint(equalTo: glassCard.leadingAnchor),
            cardStack.trailingAnchor.constraint(equalTo: glassCard.trailingAnchor),
            cardStack.bottomAnchor.constraint(equalTo: glassCard.bottomAnchor),
        ])
        contentStack.addArrangedSubview(glassCard)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 40),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 24),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -24),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }

    private func styleField(_ field: UITextField) {
        field.backgroundColor = UIColor(white: 0.12, alpha: 1)
        field.textColor = .white
        field.tintColor = BarberAppTheme.gold
        field.layer.cornerRadius = 10
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 20))
        field.leftViewMode = .always
        field.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 20))
        field.rightViewMode = .always
        field.heightAnchor.constraint(equalToConstant: 48).isActive = true
        field.attributedPlaceholder = NSAttributedString(
            string: field.placeholder ?? "",
            attributes: [.foregroundColor: BarberAppTheme.textTertiary as Any]
        )
    }

    @objc private func doLogin() {
        let username = usernameField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let password = passwordField.text ?? ""

        guard !username.isEmpty else {
            let alert = UIAlertController(title: "Usuário", message: "Informe seu usuário ou e-mail.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        guard !password.isEmpty else {
            let alert = UIAlertController(title: "Senha", message: "Informe sua senha.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        loginButton.isEnabled = false
        loadingIndicator.startAnimating()

        Task {
            do {
                let baseURL = AuthService.shared.baseURL
                let response = try await ApiService.shared.login(username: username, password: password)

                await MainActor.run {
                    self.loginButton.isEnabled = true
                    self.loadingIndicator.stopAnimating()

                    AuthService.shared.baseURL = baseURL
                    AuthService.shared.apiKey = response.api_key
                    AuthService.shared.role = response.user?.role ?? "admin"
                    AuthService.shared.barberId = response.user?.barber_id
                    AuthService.shared.userName = response.user?.name
                    AuthService.shared.tenantName = response.tenant?.name

                    guard let window = self.view.window else { return }
                    let main = MainTabViewController()
                    window.rootViewController = main
                    window.makeKeyAndVisible()
                }
            } catch let err as ApiError {
                await MainActor.run {
                    self.loginButton.isEnabled = true
                    self.loadingIndicator.stopAnimating()
                    let message: String
                    switch err {
                    case .server(let msg): message = msg
                    case .status(let code): message = "Erro \(code)"
                    case .invalidURL: message = "URL inválida"
                    case .noResponse: message = "Sem resposta do servidor"
                    }
                    let alert = UIAlertController(title: "Erro ao entrar", message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.loginButton.isEnabled = true
                    self.loadingIndicator.stopAnimating()
                    let alert = UIAlertController(title: "Erro", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            }
        }
    }
}
