// MARK: - LiquidGlassTabBar
// Tab bar com efeito Liquid Glass: blur + gradiente dourado + animação de seleção fluida
// Ícones: SF Symbols nativos da Apple

import UIKit

class LiquidGlassTabBar: UIView {

    // MARK: - Properties
    var selectedIndex: Int = 0 {
        didSet { animateSelection(from: oldValue, to: selectedIndex) }
    }
    var onTabSelected: ((Int) -> Void)?

    private var tabButtons: [LiquidGlassTabButton] = []
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let liquidIndicator = UIView()
    private let borderGlow = CAGradientLayer()

    // Tabs config — ícones SF Symbols nativos
    private let tabs: [(icon: String, label: String)] = [
        (BarberDesign.TabIcon.calendar, "Calendário"),
        (BarberDesign.TabIcon.appointments, "Agendamentos"),
        (BarberDesign.TabIcon.barbers, "Barbeiros"),
        (BarberDesign.TabIcon.services, "Serviços"),
        (BarberDesign.TabIcon.messages, "Mensagens"),
    ]

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Setup
    private func setup() {
        layer.cornerRadius = BarberDesign.tabBarRadius
        layer.cornerCurve = .continuous
        clipsToBounds = false

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.6
        layer.shadowRadius = 24
        layer.shadowOffset = CGSize(width: 0, height: 8)

        blurView.layer.cornerRadius = BarberDesign.tabBarRadius
        blurView.layer.cornerCurve = .continuous
        blurView.clipsToBounds = true
        addSubview(blurView)

        borderGlow.colors = [
            BarberDesign.gold.withAlphaComponent(0.8).cgColor,
            BarberDesign.gold.withAlphaComponent(0.0).cgColor,
            BarberDesign.gold.withAlphaComponent(0.4).cgColor,
        ]
        borderGlow.startPoint = CGPoint(x: 0, y: 0)
        borderGlow.endPoint = CGPoint(x: 1, y: 1)
        borderGlow.locations = [0, 0.5, 1]
        layer.addSublayer(borderGlow)

        let overlay = UIView()
        overlay.backgroundColor = UIColor(white: 0.06, alpha: 0.55)
        overlay.layer.cornerRadius = BarberDesign.tabBarRadius
        overlay.layer.cornerCurve = .continuous
        blurView.contentView.addSubview(overlay)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: blurView.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: blurView.bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: blurView.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: blurView.trailingAnchor),
        ])

        liquidIndicator.backgroundColor = BarberDesign.gold.withAlphaComponent(0.18)
        liquidIndicator.layer.cornerRadius = 20
        liquidIndicator.layer.cornerCurve = .continuous
        liquidIndicator.layer.borderWidth = 1
        liquidIndicator.layer.borderColor = BarberDesign.gold.withAlphaComponent(0.45).cgColor
        blurView.contentView.addSubview(liquidIndicator)

        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .center
        blurView.contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: blurView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: blurView.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: blurView.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: blurView.trailingAnchor, constant: -8),
        ])

        for (i, tab) in tabs.enumerated() {
            let btn = LiquidGlassTabButton(icon: tab.icon, label: tab.label, index: i)
            btn.onTap = { [weak self] idx in
                self?.selectedIndex = idx
                self?.onTabSelected?(idx)
            }
            stack.addArrangedSubview(btn)
            tabButtons.append(btn)
        }

        tabButtons[0].setSelected(true, animated: false)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        blurView.frame = bounds

        let borderWidth: CGFloat = 1.0
        let borderFrame = CGRect(
            x: -borderWidth, y: -borderWidth,
            width: bounds.width + borderWidth * 2,
            height: bounds.height + borderWidth * 2
        )
        borderGlow.frame = borderFrame
        borderGlow.cornerRadius = BarberDesign.tabBarRadius + 1

        let maskPath = UIBezierPath(roundedRect: borderFrame, cornerRadius: BarberDesign.tabBarRadius + 1)
        let innerPath = UIBezierPath(roundedRect: bounds, cornerRadius: BarberDesign.tabBarRadius)
        maskPath.append(innerPath)
        maskPath.usesEvenOddFillRule = true
        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        maskLayer.fillRule = .evenOdd
        borderGlow.mask = maskLayer

        updateIndicatorPosition(index: selectedIndex, animated: false)
    }

    private func animateSelection(from oldIndex: Int, to newIndex: Int) {
        if oldIndex < tabButtons.count { tabButtons[oldIndex].setSelected(false, animated: true) }
        if newIndex < tabButtons.count { tabButtons[newIndex].setSelected(true, animated: true) }
        updateIndicatorPosition(index: newIndex, animated: true)
        let impact = UIImpactFeedbackGenerator(style: .soft)
        impact.impactOccurred(intensity: 0.6)
    }

    private func updateIndicatorPosition(index: Int, animated: Bool) {
        guard bounds.width > 0, !tabButtons.isEmpty else { return }
        let tabWidth = bounds.width / CGFloat(tabs.count)
        let padding: CGFloat = 6
        let indicatorFrame = CGRect(
            x: tabWidth * CGFloat(index) + padding,
            y: (bounds.height - 40) / 2,
            width: tabWidth - padding * 2,
            height: 40
        )
        if animated {
            UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 0.72, initialSpringVelocity: 0.3, options: [.curveEaseInOut]) {
                self.liquidIndicator.frame = indicatorFrame
            }
        } else {
            liquidIndicator.frame = indicatorFrame
        }
    }

    func setBadge(_ count: Int, forTab index: Int) {
        guard index < tabButtons.count else { return }
        tabButtons[index].badgeCount = count
    }
}

// MARK: - LiquidGlassTabButton
class LiquidGlassTabButton: UIView {

    var onTap: ((Int) -> Void)?
    private let index: Int
    private let iconView = UIImageView()
    private let label = UILabel()
    private let stack = UIStackView()
    private let badgeView = UIView()
    private let badgeLabel = UILabel()

    var badgeCount: Int = 0 {
        didSet { updateBadge() }
    }

    init(icon: String, label text: String, index: Int) {
        self.index = index
        super.init(frame: .zero)
        setupButton(icon: icon, labelText: text)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func setupButton(icon: String, labelText: String) {
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        iconView.image = UIImage(systemName: icon, withConfiguration: config)
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = BarberDesign.textMuted

        label.text = labelText
        label.font = UIFont.systemFont(ofSize: 9.5, weight: .medium)
        label.textColor = BarberDesign.textMuted
        label.textAlignment = .center
        label.alpha = 0

        stack.axis = .vertical
        stack.spacing = 3
        stack.alignment = .center
        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(label)
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        badgeView.backgroundColor = BarberDesign.gold
        badgeView.layer.cornerRadius = 8
        badgeView.isHidden = true
        addSubview(badgeView)

        badgeLabel.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        badgeLabel.textColor = .black
        badgeLabel.textAlignment = .center
        badgeView.addSubview(badgeLabel)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let iconFrame = iconView.convert(iconView.bounds, to: self)
        badgeView.frame = CGRect(x: iconFrame.maxX - 6, y: iconFrame.minY - 6, width: 16, height: 16)
        badgeLabel.frame = badgeView.bounds
    }

    func setSelected(_ selected: Bool, animated: Bool) {
        let block = {
            self.iconView.tintColor = selected ? BarberDesign.gold : BarberDesign.textMuted
            self.label.textColor = selected ? BarberDesign.gold : BarberDesign.textMuted
            self.label.alpha = selected ? 1 : 0
            self.iconView.transform = selected
                ? CGAffineTransform(scaleX: 1.1, y: 1.1).translatedBy(x: 0, y: -2)
                : .identity
        }
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: []) { block() }
        } else {
            block()
        }
    }

    private func updateBadge() {
        badgeView.isHidden = badgeCount == 0
        badgeLabel.text = badgeCount > 9 ? "9+" : "\(badgeCount)"
        let w: CGFloat = badgeCount > 9 ? 22 : 16
        badgeView.frame.size = CGSize(width: w, height: 16)
        badgeLabel.frame = badgeView.bounds
    }

    @objc private func handleTap() {
        UIView.animate(withDuration: 0.1, animations: { self.transform = CGAffineTransform(scaleX: 0.88, y: 0.88) }) { _ in
            UIView.animate(withDuration: 0.2, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.8) { self.transform = .identity }
        }
        onTap?(index)
    }
}
