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

    var selectedIndex: Int = 0 {
        didSet { guard selectedIndex != oldValue else { return }
                 updateSelection(from: oldValue, to: selectedIndex) }
    }
    var onSelect: ((Int) -> Void)?

    private let items: [TabItem] = [
        .init(systemImage: "calendar",                           title: "Calendário"),
        .init(systemImage: "list.bullet.clipboard.fill",         title: "Agenda"),
        .init(systemImage: "person.2.fill",                      title: "Barbeiros"),
        .init(systemImage: "scissors",                           title: "Serviços"),
        .init(systemImage: "bubble.left.and.bubble.right.fill",  title: "Msgs"),
    ]

    private let blurView      = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterialDark))
    private let overlayView   = UIView()
    private let indicatorView = UIView()
    private var buttons       = [TabBarButton]()

    override init(frame: CGRect) { super.init(frame: frame); build() }
    required init?(coder: NSCoder) { fatalError() }

    private func build() {
        // Outer shadow
        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowOpacity = 0.65
        layer.shadowRadius  = 24
        layer.shadowOffset  = CGSize(width: 0, height: 8)
        layer.cornerRadius  = BarberTheme.tabBarRadius
        layer.cornerCurve   = .continuous

        // CRÍTICO: translatesAutoresizingMaskIntoConstraints = false no blurView
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = BarberTheme.tabBarRadius
        blurView.layer.cornerCurve  = .continuous
        blurView.clipsToBounds      = true
        addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        // Dark overlay
        overlayView.backgroundColor    = UIColor(white: 0.05, alpha: 0.60)
        overlayView.layer.cornerRadius = BarberTheme.tabBarRadius
        overlayView.layer.cornerCurve  = .continuous
        blurView.contentView.addSubview(overlayView)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlayView.topAnchor.constraint(equalTo: blurView.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: blurView.bottomAnchor),
            overlayView.leadingAnchor.constraint(equalTo: blurView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: blurView.trailingAnchor),
        ])

        // Gold border via layer
        let borderLayer = CALayer()
        borderLayer.borderColor = BarberTheme.gold.withAlphaComponent(0.35).cgColor
        borderLayer.borderWidth = 1
        borderLayer.cornerRadius = BarberTheme.tabBarRadius
        blurView.contentView.layer.addSublayer(borderLayer)
        blurView.contentView.layer.setValue(borderLayer, forKey: "borderLayer")

        // Sliding indicator pill
        indicatorView.backgroundColor    = BarberTheme.gold.withAlphaComponent(0.14)
        indicatorView.layer.cornerRadius = 18
        indicatorView.layer.cornerCurve  = .continuous
        indicatorView.layer.borderWidth  = 1
        indicatorView.layer.borderColor  = BarberTheme.gold.withAlphaComponent(0.40).cgColor
        blurView.contentView.addSubview(indicatorView)

        // Buttons stack
        let stack = UIStackView()
        stack.axis         = .horizontal
        stack.distribution = .fillEqually
        stack.alignment    = .center
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
                guard let self else { return }
                self.selectedIndex = i
                self.onSelect?(i)
            }
            stack.addArrangedSubview(btn)
            buttons.append(btn)
        }
        buttons.first?.setState(.selected, animated: false)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if let border = blurView.contentView.layer.value(forKey: "borderLayer") as? CALayer {
            border.frame = blurView.contentView.bounds
        }
        placeIndicator(at: selectedIndex, animated: false)
    }

    private func updateSelection(from old: Int, to new: Int) {
        if old < buttons.count { buttons[old].setState(.normal, animated: true) }
        if new < buttons.count { buttons[new].setState(.selected, animated: true) }
        placeIndicator(at: new, animated: true)
        UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.5)
    }

    private func placeIndicator(at index: Int, animated: Bool) {
        guard bounds.width > 0, !buttons.isEmpty else { return }
        let w   = bounds.width / CGFloat(items.count)
        let pad = CGFloat(6)
        let f   = CGRect(x: w * CGFloat(index) + pad,
                         y: (bounds.height - 40) / 2,
                         width: w - pad * 2, height: 40)
        if animated {
            UIView.animate(withDuration: 0.4, delay: 0,
                           usingSpringWithDamping: 0.68,
                           initialSpringVelocity: 0.2) { self.indicatorView.frame = f }
        } else {
            indicatorView.frame = f
        }
    }

    func setBadge(_ count: Int, at index: Int) {
        guard index < buttons.count else { return }
        buttons[index].setBadge(count)
    }
}

// MARK: - TabBarButton (sem constraints conflitantes no label)
private final class TabBarButton: UIView {
    enum State { case normal, selected }
    var onTap: ((Int) -> Void)?
    private let index: Int
    private let iconView   = UIImageView()
    private let titleLabel = UILabel()
    private let badgeView  = UIView()
    private let badgeLabel = UILabel()

    init(item: TabItem, index: Int) {
        self.index = index
        super.init(frame: .zero)

        let cfg = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        iconView.image       = UIImage(systemName: item.systemImage, withConfiguration: cfg)
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor   = BarberTheme.textMuted

        titleLabel.text          = item.title
        titleLabel.font          = .systemFont(ofSize: 9, weight: .semibold)
        titleLabel.textColor     = BarberTheme.textMuted
        titleLabel.textAlignment = .center
        titleLabel.alpha         = 0

        badgeView.backgroundColor    = BarberTheme.gold
        badgeView.layer.cornerRadius = 7
        badgeView.isHidden           = true
        badgeLabel.font              = .systemFont(ofSize: 9, weight: .black)
        badgeLabel.textColor         = .black
        badgeLabel.textAlignment     = .center
        badgeView.addSubview(badgeLabel)

        [iconView, titleLabel, badgeView].forEach {
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -5),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 3),
            titleLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.9),
        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        let iconF  = iconView.convert(iconView.bounds, to: self)
        let bw: CGFloat = (badgeLabel.text?.count ?? 0) > 1 ? 22 : 16
        badgeView.frame            = CGRect(x: iconF.maxX - 5, y: iconF.minY - 5, width: bw, height: 14)
        badgeLabel.frame           = badgeView.bounds
        badgeView.layer.cornerRadius = 7
    }

    func setState(_ state: State, animated: Bool) {
        let isOn = state == .selected
        let block = {
            self.iconView.tintColor   = isOn ? BarberTheme.gold : BarberTheme.textMuted
            self.titleLabel.textColor = isOn ? BarberTheme.gold : BarberTheme.textMuted
            self.titleLabel.alpha     = isOn ? 1 : 0
            self.iconView.transform   = isOn
                ? CGAffineTransform(translationX: 0, y: -3).scaledBy(x: 1.08, y: 1.08)
                : .identity
        }
        if animated {
            UIView.animate(withDuration: 0.28, delay: 0,
                           usingSpringWithDamping: 0.7,
                           initialSpringVelocity: 0.4, animations: block)
        } else {
            block()
        }
    }

    func setBadge(_ count: Int) {
        badgeView.isHidden = count == 0
        badgeLabel.text    = count > 9 ? "9+" : "\(count)"
        setNeedsLayout()
    }

    @objc private func tapped() {
        UIView.animate(withDuration: 0.08,
                       animations: { self.transform = CGAffineTransform(scaleX: 0.85, y: 0.85) }) { _ in
            UIView.animate(withDuration: 0.25, delay: 0,
                           usingSpringWithDamping: 0.5,
                           initialSpringVelocity: 0.8) { self.transform = .identity }
        }
        onTap?(index)
    }
}
