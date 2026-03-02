//
//  MessagesViewController.swift
//  BarberApp
//
//  Inbox de conversas WhatsApp (prioridade / aguardando atendente)
//

import UIKit

class MessagesViewController: UIViewController {

    private var conversations: [Conversation] = []
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private var refreshControl = UIRefreshControl()

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Mensagens"
        view.backgroundColor = BarberTheme.bg
        navigationController?.navigationBar.prefersLargeTitles = true
        setupTableView()
        loadConversations()

        Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.loadConversations()
        }
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorColor = BarberTheme.border
        tableView.register(ConversationCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 80
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)

        refreshControl.tintColor = BarberTheme.gold
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

        emptyLabel.text = "Nenhuma conversa ainda"
        emptyLabel.textColor = BarberTheme.textMuted
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

    private func loadConversations() {
        ApiService.shared.getPriorityConversations { [weak self] result in
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
                switch result {
                case .success(let convs):
                    self?.conversations = convs
                    self?.tableView.reloadData()
                    self?.emptyLabel.isHidden = !convs.isEmpty
                case .failure:
                    break
                }
            }
        }
    }

    @objc private func handleRefresh() {
        loadConversations()
    }
}

extension MessagesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        conversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ConversationCell
        cell.configure(with: conversations[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let conv = conversations[indexPath.row]
        let chatVC = ChatViewController(phone: conv.customerPhone, name: conv.customerName)
        navigationController?.pushViewController(chatVC, animated: true)
    }
}

// MARK: - ConversationCell
final class ConversationCell: UITableViewCell {

    private let avatarView = UIView()
    private let avatarLabel = UILabel()
    private let nameLabel = UILabel()
    private let previewLabel = UILabel()
    private let timeLabel = UILabel()
    private let unreadBadge = UIView()
    private let unreadLabel = UILabel()
    private let waitingIndicator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        setupUI()
        let bg = UIView()
        bg.backgroundColor = UIColor(white: 1, alpha: 0.04)
        selectedBackgroundView = bg
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        avatarView.backgroundColor = BarberTheme.surface
        avatarView.layer.cornerRadius = 24
        avatarView.layer.borderWidth = 1.5
        avatarView.layer.borderColor = BarberTheme.gold.withAlphaComponent(0.3).cgColor
        contentView.addSubview(avatarView)

        avatarLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        avatarLabel.textColor = BarberTheme.gold
        avatarLabel.textAlignment = .center
        avatarView.addSubview(avatarLabel)

        waitingIndicator.backgroundColor = BarberTheme.success
        waitingIndicator.layer.cornerRadius = 6
        waitingIndicator.layer.borderWidth = 2
        waitingIndicator.layer.borderColor = BarberTheme.bg.cgColor
        waitingIndicator.isHidden = true
        contentView.addSubview(waitingIndicator)

        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = BarberTheme.textPrimary
        contentView.addSubview(nameLabel)

        previewLabel.font = .systemFont(ofSize: 13)
        previewLabel.textColor = BarberTheme.textSecond
        previewLabel.numberOfLines = 1
        contentView.addSubview(previewLabel)

        timeLabel.font = .systemFont(ofSize: 11)
        timeLabel.textColor = BarberTheme.textMuted
        contentView.addSubview(timeLabel)

        unreadBadge.backgroundColor = BarberTheme.gold
        unreadBadge.layer.cornerRadius = 10
        unreadBadge.isHidden = true
        contentView.addSubview(unreadBadge)

        unreadLabel.font = .systemFont(ofSize: 11, weight: .bold)
        unreadLabel.textColor = .black
        unreadLabel.textAlignment = .center
        unreadBadge.addSubview(unreadLabel)

        let p: CGFloat = 16
        let avatarSize: CGFloat = 48
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        unreadBadge.translatesAutoresizingMaskIntoConstraints = false
        unreadLabel.translatesAutoresizingMaskIntoConstraints = false
        waitingIndicator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: p),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: avatarSize),
            avatarView.heightAnchor.constraint(equalToConstant: avatarSize),
            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            waitingIndicator.trailingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 2),
            waitingIndicator.bottomAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 2),
            waitingIndicator.widthAnchor.constraint(equalToConstant: 12),
            waitingIndicator.heightAnchor.constraint(equalToConstant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: timeLabel.leadingAnchor, constant: -8),
            previewLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            previewLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 3),
            previewLabel.trailingAnchor.constraint(lessThanOrEqualTo: unreadBadge.leadingAnchor, constant: -8),
            timeLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
            timeLabel.topAnchor.constraint(equalTo: nameLabel.topAnchor),
            unreadBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -p),
            unreadBadge.centerYAnchor.constraint(equalTo: previewLabel.centerYAnchor),
            unreadBadge.heightAnchor.constraint(equalToConstant: 20),
            unreadBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            unreadLabel.centerXAnchor.constraint(equalTo: unreadBadge.centerXAnchor),
            unreadLabel.centerYAnchor.constraint(equalTo: unreadBadge.centerYAnchor),
            unreadLabel.leadingAnchor.constraint(equalTo: unreadBadge.leadingAnchor, constant: 4),
            unreadLabel.trailingAnchor.constraint(equalTo: unreadBadge.trailingAnchor, constant: -4),
        ])
    }

    func configure(with conv: Conversation) {
        let name = conv.customerName ?? conv.customerPhone
        nameLabel.text = name
        previewLabel.text = conv.lastMessage
        avatarLabel.text = String(name.prefix(1)).uppercased()
        waitingIndicator.isHidden = !conv.isWaitingAttendant

        if conv.unreadCount > 0 {
            unreadBadge.isHidden = false
            unreadLabel.text = conv.unreadCount > 9 ? "9+" : "\(conv.unreadCount)"
        } else {
            unreadBadge.isHidden = true
        }

        let diff = Date().timeIntervalSince(conv.lastMessageDate)
        if diff < 3600 {
            timeLabel.text = "\(Int(diff/60))min"
        } else if diff < 86400 {
            timeLabel.text = "\(Int(diff/3600))h"
        } else {
            let fmt = DateFormatter()
            fmt.dateFormat = "dd/MM"
            timeLabel.text = fmt.string(from: conv.lastMessageDate)
        }
    }
}
