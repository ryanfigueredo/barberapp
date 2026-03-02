//
//  MainTabViewController.swift
//  BarberApp
//
//  Tab principal: Calendário | Agendamentos | Barbeiros | Serviços | Mensagens
//  Liquid Glass tab bar + nav bar dark luxury
//

import UIKit

class MainTabViewController: UIViewController {

    private let tabBar = LiquidGlassTabBar()
    private var viewControllers: [UIViewController] = []
    private var currentVC: UIViewController?
    private var currentIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BarberAppTheme.background
        setupViewControllers()
        setupTabBar()
        showViewController(at: 0)
    }

    private func setupViewControllers() {
        let cal = CalendarViewController()
        cal.baseURL = AuthService.shared.baseURL
        cal.apiKey = AuthService.shared.apiKey

        viewControllers = [
            UINavigationController(rootViewController: cal),
            UINavigationController(rootViewController: AppointmentsViewController()),
            UINavigationController(rootViewController: BarbersViewController()),
            UINavigationController(rootViewController: ServicesViewController()),
            UINavigationController(rootViewController: MessagesViewController()),
        ]

        viewControllers.forEach { vc in
            guard let nav = vc as? UINavigationController else { return }
            let appearance = UINavigationBarAppearance()
            appearance.configureWithTransparentBackground()
            appearance.backgroundColor = BarberAppTheme.card
            appearance.titleTextAttributes = [
                .foregroundColor: BarberAppTheme.gold,
                .font: UIFont.systemFont(ofSize: 18, weight: .bold),
            ]
            appearance.largeTitleTextAttributes = [
                .foregroundColor: BarberAppTheme.gold,
                .font: UIFont.systemFont(ofSize: 32, weight: .bold),
            ]
            nav.navigationBar.standardAppearance = appearance
            nav.navigationBar.scrollEdgeAppearance = appearance
            nav.navigationBar.tintColor = BarberAppTheme.gold
        }
    }

    private func setupTabBar() {
        view.addSubview(tabBar)
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: BarberDesign.tabBarMargin),
            tabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -BarberDesign.tabBarMargin),
            tabBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -BarberDesign.tabBarBottomOffset),
            tabBar.heightAnchor.constraint(equalToConstant: BarberDesign.tabBarHeight),
        ])
        tabBar.onTabSelected = { [weak self] index in
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

    func setBadge(_ count: Int, forTab index: Int) {
        tabBar.setBadge(count, forTab: index)
    }
}
