//
//  LiquidGlassTabBar.swift
//  BarberApp
//
//  Tab bar Liquid Glass: blur + pill dourado animado + SF Symbols
//

import UIKit

struct TabItem {
    let systemImage: String
    let title: String
}

final class LiquidGlassTabBar: UIView {

    private let items: [TabItem] = [
        TabItem(systemImage: "calendar", title: "Calendário"),
        TabItem(systemImage: "list.bullet.clipboard.fill", title: "Agenda"),
        TabItem(systemImage: "person.2.fill", title: "Barbeiros"),
        TabItem(systemImage: "scissors", title: "Serviços"),
        TabItem(systemImage: "bubble.left.and.bubble.right.fill", title: "Mensagens"),
    ]

    var selectedIndex: Int = 0 {
        didSet {
            guard selectedIndex != oldValue else { return }
            updateSelection(from: oldValue, to: selectedIndex)
        }
    }
    var onSelect: ((Int) -> Void)?

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
    private let overlayView = UIView()
    private let indicatorView = UIView()
    private var buttons = [TabBarButton]()
    private var goldBorderLayer = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func build() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.65
        layer.shadowRadius = 28
        layer.shadowOffset = CGSize(width: 0, height: 10)
        layer.cornerRadius = BarberTheme.tabBarRadius
        layer.cornerCurve = .continuous

        blurView.layer.cornerRadius = BarberTheme.tabBarRadius
        blurView.layer.cornerCurve = .continuous
        blurView.clipsToBounds = true
        addSubview(blurView)

        overlayView.backgroundColor = UIColor(white: 0.05, alpha: 0.60)
        overlayView.layer.cornerRadius = BarberTheme.tabBarRadius
        overlayView.layer.cornerCurve = .continuous
        blurView.contentView.addSubview(overlayView)

        goldBorderLayer.colors = [
            BarberTheme.gold.withAlphaComponent(0.55).cgColor,
            BarberTheme.gold.withAlphaComponent(0.10).cgColor,
            BarberTheme.gold.withAlphaComponent(0.40).cgColor,
        ]
        goldBorderLayer.locations = [0, 0.45, 1]
        goldBorderLayer.startPoint = CGPoint(x: 0, y: 0)
        goldBorderLayer.endPoint = CGPoint(x: 1, y: 1)
        goldBorderLayer.cornerRadius = BarberTheme.tabBarRadius
        blurView.contentView.layer.addSublayer(goldBorderLayer)

        indicatorView.backgroundColor = BarberTheme.gold.withAlphaComponent(0.14)
        indicatorView.layer.cornerRadius = 20
        indicatorView.layer.cornerCurve = .continuous
        indicatorView.layer.borderWidth = 1
        indicatorView.layer.borderColor = BarberTheme.gold.withAlphaComponent(0.40).cgColor
        blurView.contentView.addSubview(indicatorView)

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        blurView.contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: blurView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: blurView.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: blurView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: blurView.trailingAnchor),
        ])

        items.enumerated().forEach { idx, item in
            let btn = TabBarButton(item: item, index: idx)
            btn.onTap = { [weak self] i in
                self?.selectedIndex = i
                self?.onSelect?(i)
            }
            stack.addArrangedSubview(btn)
            buttons.append(btn)
        }

        buttons.first?.setState(.selected, animated: false)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        blurView.frame = bounds
        overlayView.frame = bounds

        let bw: CGFloat = 1.0
        goldBorderLayer.frame = CGRect(x: -bw, y: -bw, width: bounds.width + bw * 2, height: bounds.height + bw * 2)
        goldBorderLayer.cornerRadius = BarberTheme.tabBarRadius + 1

        let outerPath = UIBezierPath(roundedRect: CGRect(x: -bw, y: -bw, width: bounds.width + bw * 2, height: bounds.height + bw * 2), cornerRadius: BarberTheme.tabBarRadius + 1)
        let innerPath = UIBezierPath(roundedRect: bounds, cornerRadius: BarberTheme.tabBarRadius)
        outerPath.append(innerPath)
        outerPath.usesEvenOddFillRule = true
        let maskLayer = CAShapeLayer()
        maskLayer.path = outerPath.cgPath
        maskLayer.fillRule = .evenOdd
        goldBorderLayer.mask = maskLayer

        placeIndicator(at: selectedIndex, animated: false)
    }

    private func updateSelection(from old: Int, to new: Int) {
        if old < buttons.count { buttons[old].setState(.normal, animated: true) }
        if new < buttons.count { buttons[new].setState(.selected, animated: true) }
        placeIndicator(at: new, animated: true)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5)
    }

    private func placeIndicator(at index: Int, animated: Bool) {
        guard bounds.width > 0 else { return }
        let w = bounds.width / CGFloat(items.count)
        let pad: CGFloat = 8
        let frame = CGRect(x: w * CGFloat(index) + pad,
                           y: (bounds.height - 42) / 2,
                           width: w - pad * 2,
                           height: 42)
        if animated {
            UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 0.68, initialSpringVelocity: 0.25, options: []) {
                self.indicatorView.frame = frame
            }
        } else {
            indicatorView.frame = frame
        }
    }

    func setBadge(_ count: Int, at index: Int) {
        guard index < buttons.count else { return }
        buttons[index].setBadge(count)
    }
}

// MARK: - TabBarButton
private final class TabBarButton: UIView {

    enum State { case normal, selected }

    var onTap: ((Int) -> Void)?
    private let index: Int
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let badgeView = UIView()
    private let badgeLabel = UILabel()

    init(item: TabItem, index: Int) {
        self.index = index
        super.init(frame: .zero)

        let cfg = UIImage.SymbolConfiguration(pointSize: 21, weight: .medium, scale: .default)
        iconView.image = UIImage(systemName: item.systemImage, withConfiguration: cfg)
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = BarberTheme.textMuted
        iconView.setContentHuggingPriority(.required, for: .vertical)
        addSubview(iconView)

        titleLabel.text = item.title
        titleLabel.font = .systemFont(ofSize: 9.5, weight: .semibold)
        titleLabel.textColor = BarberTheme.textMuted
        titleLabel.textAlignment = .center
        titleLabel.alpha = 0
        addSubview(titleLabel)

        badgeView.backgroundColor = BarberTheme.gold
        badgeView.layer.cornerRadius = 8
        badgeView.isHidden = true
        addSubview(badgeView)

        badgeLabel.font = .systemFont(ofSize: 9, weight: .black)
        badgeLabel.textColor = .black
        badgeLabel.textAlignment = .center
        badgeView.addSubview(badgeLabel)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -4),
            iconView.widthAnchor.constraint(equalToConstant: 26),
            iconView.heightAnchor.constraint(equalToConstant: 26),
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 3),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let iconF = iconView.convert(iconView.bounds, to: self)
        let bw: CGFloat = (badgeLabel.text?.count ?? 0) > 1 ? 22 : 16
        badgeView.frame = CGRect(x: iconF.maxX - 6, y: iconF.minY - 5, width: bw, height: 15)
        badgeLabel.frame = badgeView.bounds
        badgeView.layer.cornerRadius = 7.5
    }

    func setState(_ state: State, animated: Bool) {
        let isSelected = state == .selected
        let block = {
            self.iconView.tintColor = isSelected ? BarberTheme.gold : BarberTheme.textMuted
            self.titleLabel.textColor = isSelected ? BarberTheme.gold : BarberTheme.textMuted
            self.titleLabel.alpha = isSelected ? 1 : 0
            self.iconView.transform = isSelected
                ? CGAffineTransform(translationX: 0, y: -3).scaledBy(x: 1.08, y: 1.08)
                : .identity
        }
        if animated {
            UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.4, options: [], animations: block)
        } else {
            block()
        }
    }

    func setBadge(_ count: Int) {
        badgeView.isHidden = count == 0
        badgeLabel.text = count > 9 ? "9+" : "\(count)"
        setNeedsLayout()
    }

    @objc private func tapped() {
        UIView.animate(withDuration: 0.08, animations: { self.transform = CGAffineTransform(scaleX: 0.85, y: 0.85) }) { _ in
            UIView.animate(withDuration: 0.25, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8, options: []) {
                self.transform = .identity
            }
        }
        onTap?(index)
    }
}
