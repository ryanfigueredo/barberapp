//
//  ChatViewController.swift
//  BarberApp
//
//  Chat com um cliente (WhatsApp inbox) — input glass, bolhas cliente/barbeiro
//

import UIKit

class ChatViewController: UIViewController {

    private let phone: String
    private let customerName: String?
    private var messages: [ChatMessage] = []

    private let tableView = UITableView()
    private let inputContainer = UIView()
    private let textField = UITextField()
    private let sendButton = UIButton()
    private let blurInput = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))

    init(phone: String, name: String?) {
        self.phone = phone
        self.customerName = name
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = customerName ?? phone
        view.backgroundColor = BarberAppTheme.background
        setupTableView()
        setupInputBar()
        loadMessages()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(MessageBubbleCell.self, forCellReuseIdentifier: "bubble")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80),
        ])
    }

    private func setupInputBar() {
        blurInput.layer.cornerRadius = 24
        blurInput.layer.cornerCurve = .continuous
        blurInput.clipsToBounds = true
        blurInput.layer.borderWidth = 1
        blurInput.layer.borderColor = BarberAppTheme.gold.withAlphaComponent(0.25).cgColor
        view.addSubview(blurInput)
        blurInput.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurInput.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            blurInput.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            blurInput.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            blurInput.heightAnchor.constraint(equalToConstant: 52),
        ])

        textField.placeholder = "Digite uma mensagem..."
        textField.textColor = .white
        textField.tintColor = BarberAppTheme.gold
        textField.attributedPlaceholder = NSAttributedString(
            string: "Digite uma mensagem...",
            attributes: [.foregroundColor: BarberAppTheme.textTertiary as Any]
        )
        blurInput.contentView.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false

        let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .medium)
        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill", withConfiguration: config), for: .normal)
        sendButton.tintColor = BarberAppTheme.gold
        sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        blurInput.contentView.addSubview(sendButton)
        sendButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: blurInput.contentView.leadingAnchor, constant: 20),
            textField.centerYAnchor.constraint(equalTo: blurInput.contentView.centerYAnchor),
            textField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -8),
            sendButton.trailingAnchor.constraint(equalTo: blurInput.contentView.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: blurInput.contentView.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    private func loadMessages() {
        ApiService.shared.getConversationHistory(phone: phone) { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let msgs) = result {
                    self?.messages = msgs.reversed()
                    self?.tableView.reloadData()
                }
            }
        }
    }

    @objc private func sendMessage() {
        guard let text = textField.text?.trimmingCharacters(in: .whitespaces), !text.isEmpty else { return }
        textField.text = ""

        let msg = ChatMessage(id: UUID().uuidString, text: text, isAttendant: true, timestamp: Date(), status: "sending")
        messages.insert(msg, at: 0)
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .bottom)

        ApiService.shared.sendWhatsAppMessage(phone: phone, message: text) { _ in }
    }

    @objc private func keyboardWillShow(_ notif: Notification) {
        guard let frame = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let duration = notif.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        UIView.animate(withDuration: duration) {
            self.blurInput.transform = CGAffineTransform(translationX: 0, y: -(frame.height - self.view.safeAreaInsets.bottom))
        }
    }

    @objc private func keyboardWillHide(_ notif: Notification) {
        let duration = notif.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        UIView.animate(withDuration: duration) {
            self.blurInput.transform = .identity
        }
    }
}

extension ChatViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bubble", for: indexPath) as! MessageBubbleCell
        cell.configure(with: messages[indexPath.row])
        cell.transform = CGAffineTransform(scaleX: 1, y: -1)
        return cell
    }
}

// MARK: - MessageBubbleCell
final class MessageBubbleCell: UITableViewCell {
    private let bubble = UIView()
    private let msgLabel = UILabel()
    private let timeLabel = UILabel()
    private var leadingConstraint: NSLayoutConstraint?
    private var trailingConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        bubble.layer.cornerRadius = 16
        bubble.layer.cornerCurve = .continuous
        contentView.addSubview(bubble)

        msgLabel.numberOfLines = 0
        msgLabel.font = .systemFont(ofSize: 15)
        bubble.addSubview(msgLabel)

        timeLabel.font = .systemFont(ofSize: 10)
        timeLabel.textColor = BarberAppTheme.textTertiary
        contentView.addSubview(timeLabel)

        bubble.translatesAutoresizingMaskIntoConstraints = false
        msgLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            bubble.bottomAnchor.constraint(equalTo: timeLabel.topAnchor, constant: -2),
            bubble.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),
            msgLabel.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 10),
            msgLabel.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -10),
            msgLabel.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 12),
            msgLabel.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -12),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),
        ])

        leadingConstraint = bubble.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingConstraint = bubble.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
    }
    required init?(coder: NSCoder) { fatalError() }

    func configure(with msg: ChatMessage) {
        msgLabel.text = msg.text
        msgLabel.textColor = msg.isAttendant ? UIColor(white: 0.05, alpha: 1) : .white

        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        timeLabel.text = fmt.string(from: msg.timestamp)

        leadingConstraint?.isActive = false
        trailingConstraint?.isActive = false

        if msg.isAttendant {
            bubble.backgroundColor = BarberAppTheme.gold
            trailingConstraint?.isActive = true
        } else {
            bubble.backgroundColor = BarberAppTheme.card
            leadingConstraint?.isActive = true
        }
    }
}
