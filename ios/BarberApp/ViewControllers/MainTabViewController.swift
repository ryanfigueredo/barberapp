//
//  MainTabViewController.swift
//  BarberApp
//
//  Tab principal + botão Configurações na nav bar
//

import UIKit

final class MainTabViewController: UIViewController {

    private let tabBar = LiquidGlassTabBar()
    private var vcs: [UINavigationController] = []
    private var currentIndex = 0
    private weak var currentVC: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BarberTheme.bg
        buildViewControllers()
        addTabBar()
        show(index: 0, animated: false)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    override var childForStatusBarStyle: UIViewController? { currentVC }

    // MARK: - Setup
    private func buildViewControllers() {
        let pairs: [(UIViewController, String)] = [
            (CalendarViewController(),      "Calendário"),
            (AppointmentsViewController(),  "Agendamentos"),
            (BarbersViewController(),       "Barbeiros"),
            (ServicesViewController(),      "Serviços"),
            (MessagesViewController(),      "Mensagens"),
        ]
        vcs = pairs.map { (vc, title) in
            vc.title = title
            let nav  = UINavigationController(rootViewController: vc)
            styleNav(nav)
            vc.navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "gearshape.fill",
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)),
                style: .plain, target: self, action: #selector(openSettings)
            )
            vc.navigationItem.rightBarButtonItem?.tintColor = BarberTheme.gold
            return nav
        }
    }

    private func styleNav(_ nav: UINavigationController) {
        let a = UINavigationBarAppearance()
        a.configureWithOpaqueBackground()
        a.backgroundColor         = UIColor(white: 0.05, alpha: 1)
        a.titleTextAttributes     = [.foregroundColor: BarberTheme.gold,
                                     .font: UIFont.systemFont(ofSize: 18, weight: .bold)]
        a.largeTitleTextAttributes = [.foregroundColor: BarberTheme.gold,
                                      .font: UIFont.systemFont(ofSize: 32, weight: .heavy)]
        nav.navigationBar.standardAppearance   = a
        nav.navigationBar.scrollEdgeAppearance = a
        nav.navigationBar.compactAppearance    = a
        nav.navigationBar.isTranslucent        = false
        nav.navigationBar.tintColor            = BarberTheme.gold
        nav.navigationBar.prefersLargeTitles   = true
    }

    private func addTabBar() {
        view.addSubview(tabBar)
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -28),
            tabBar.heightAnchor.constraint(equalToConstant: 68),
        ])
        tabBar.onSelect = { [weak self] index in
            self?.show(index: index, animated: true)
        }
    }

    // MARK: - Navigation
    private func show(index: Int, animated: Bool) {
        guard index < vcs.count else { return }
        let newVC = vcs[index]

        if let current = currentVC {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }

        addChild(newVC)
        view.insertSubview(newVC.view, belowSubview: tabBar)
        newVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            newVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            newVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            newVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            newVC.view.bottomAnchor.constraint(equalTo: tabBar.topAnchor),
        ])
        newVC.didMove(toParent: self)

        if animated && currentVC != nil {
            newVC.view.alpha = 0
            UIView.animate(withDuration: 0.2) { newVC.view.alpha = 1 }
        }

        currentVC    = newVC
        currentIndex = index
        tabBar.selectedIndex = index
        setNeedsStatusBarAppearanceUpdate()
    }

    @objc private func openSettings() {
        let nav = UINavigationController(rootViewController: SettingsViewController())
        styleNav(nav)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }
}
