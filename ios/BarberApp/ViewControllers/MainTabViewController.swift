//
//  MainTabViewController.swift
//  BarberApp
//
//  Tab principal + botão Configurações na nav bar
//

import UIKit

class MainTabViewController: UIViewController {

    private let tabBar = LiquidGlassTabBar()
    private var viewControllers: [UIViewController] = []
    private var currentVC: UIViewController?
    private var currentIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BarberTheme.bg
        setupViewControllers()
        setupTabBar()
        showViewController(at: 0)
    }

    private func setupViewControllers() {
        viewControllers = [
            wrapInNav(CalendarViewController(), title: "Calendário"),
            wrapInNav(AppointmentsViewController(), title: "Agendamentos"),
            wrapInNav(BarbersViewController(), title: "Barbeiros"),
            wrapInNav(ServicesViewController(), title: "Serviços"),
            wrapInNav(MessagesViewController(), title: "Mensagens"),
        ]
    }

    private func wrapInNav(_ vc: UIViewController, title: String) -> UINavigationController {
        let nav = UINavigationController(rootViewController: vc)
        vc.navigationItem.title = title

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(white: 0.06, alpha: 0.97)
        appearance.titleTextAttributes = [
            .foregroundColor: BarberTheme.gold,
            .font: UIFont.systemFont(ofSize: 18, weight: .bold),
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: BarberTheme.gold,
            .font: UIFont.systemFont(ofSize: 30, weight: .bold),
        ]
        nav.navigationBar.standardAppearance = appearance
        nav.navigationBar.scrollEdgeAppearance = appearance
        nav.navigationBar.tintColor = BarberTheme.gold

        let settingsBtn = UIBarButtonItem(
            image: UIImage(systemName: "gearshape.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .medium)),
            style: .plain,
            target: self,
            action: #selector(openSettings)
        )
        vc.navigationItem.rightBarButtonItem = settingsBtn

        return nav
    }

    private func setupTabBar() {
        view.addSubview(tabBar)
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: BarberTheme.tabBarSideMargin),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -BarberTheme.tabBarSideMargin),
            tabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -BarberTheme.tabBarBottomOffset),
            tabBar.heightAnchor.constraint(equalToConstant: BarberTheme.tabBarHeight),
        ])
        tabBar.onSelect = { [weak self] index in
            self?.showViewController(at: index)
        }
    }

    private func showViewController(at index: Int) {
        guard index < viewControllers.count else { return }
        let newVC = viewControllers[index]

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
            newVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        newVC.didMove(toParent: self)

        if currentVC != nil {
            newVC.view.alpha = 0
            UIView.animate(withDuration: 0.22) { newVC.view.alpha = 1 }
        }

        currentVC = newVC
        currentIndex = index
        tabBar.selectedIndex = index
    }

    @objc private func openSettings() {
        let vc = SettingsViewController()
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }

    func setBadge(_ count: Int, forTab index: Int) {
        tabBar.setBadge(count, at: index)
    }
}
