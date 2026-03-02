//
//  LoginViewController.swift
//  BarberApp
//
//  Tela de login: Base URL + API Key → salva em AuthService e apresenta MainTab
//

import UIKit

class LoginViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let titleLabel = UILabel()
    private let baseURLField = UITextField()
    private let apiKeyField = UITextField()
    private let loginButton = UIButton(type: .system)
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

        glassCard.backgroundColor = BarberAppTheme.card
        glassCard.layer.cornerRadius = 16
        glassCard.layer.borderWidth = 1
        glassCard.layer.borderColor = BarberAppTheme.gold.withAlphaComponent(0.25).cgColor
        let cardStack = UIStackView()
        cardStack.axis = .vertical
        cardStack.spacing = 16
        cardStack.isLayoutMarginsRelativeArrangement = true
        cardStack.layoutMargins = UIEdgeInsets(top: 24, left: 20, bottom: 24, right: 20)

        baseURLField.placeholder = "Base URL (ex: http://localhost:3000)"
        styleField(baseURLField)
        baseURLField.text = AuthService.shared.baseURL
        baseURLField.keyboardType = .URL
        baseURLField.autocapitalizationType = .none
        cardStack.addArrangedSubview(baseURLField)

        apiKeyField.placeholder = "API Key"
        styleField(apiKeyField)
        apiKeyField.text = AuthService.shared.apiKey
        apiKeyField.isSecureTextEntry = true
        cardStack.addArrangedSubview(apiKeyField)

        loginButton.setTitle("Entrar", for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        loginButton.setTitleColor(BarberAppTheme.background, for: .normal)
        loginButton.backgroundColor = BarberAppTheme.gold
        loginButton.layer.cornerRadius = 12
        loginButton.addTarget(self, action: #selector(doLogin), for: .touchUpInside)
        cardStack.addArrangedSubview(loginButton)

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
        let base = baseURLField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let key = apiKeyField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        guard !key.isEmpty else {
            let alert = UIAlertController(title: "API Key", message: "Informe a API Key.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        AuthService.shared.baseURL = base.isEmpty ? "http://localhost:3000" : base
        AuthService.shared.apiKey = key

        guard let window = view.window else { return }
        let main = MainTabViewController()
        window.rootViewController = main
        window.makeKeyAndVisible()
    }
}
