//
//  MainTabViewController.swift
//  BarberApp
//
//  Usa UITabBarController nativo — sem constraint conflicts.
//

import UIKit

final class MainTabViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BarberTheme.bg
        setupViewControllers()
        styleTabBar()
        requestNotificationPermissionAndSchedule()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    @objc private func appWillEnterForeground() {
        fetchUpcomingAndScheduleNotifications()
    }

    /// Pede permissão de notificações e agenda lembretes dos próximos agendamentos.
    private func requestNotificationPermissionAndSchedule() {
        AppointmentNotificationService.shared.requestPermission { [weak self] _ in
            self?.fetchUpcomingAndScheduleNotifications()
        }
    }

    private func fetchUpcomingAndScheduleNotifications() {
        ApiService.shared.fetch("/api/app/appointments?upcoming=true") { [weak self] (result: Result<AppointmentsResponse, Error>) in
            if case .success(let r) = result {
                AppointmentNotificationService.shared.scheduleForAppointments(r.appointments)
            }
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private func setupViewControllers() {
        let pairs: [(UIViewController, String, String)] = [
            (DashboardViewController(), "Visão", "chart.bar.fill"),
            (CalendarViewController(), "Calendário", "calendar"),
            (AppointmentsViewController(), "Agendamentos", "list.bullet.clipboard.fill"),
            (BarbersViewController(), "Barbeiros", "person.2.fill"),
            (ServicesViewController(), "Serviços", "scissors"),
            (MessagesViewController(), "Mensagens", "bubble.left.and.bubble.right.fill"),
        ]
        viewControllers = pairs.map { vc, title, icon in
            vc.title = title
            let nav = UINavigationController(rootViewController: vc)
            styleNav(nav)
            let item = UITabBarItem(
                title: title,
                image: UIImage(systemName: icon),
                selectedImage: UIImage(systemName: icon)
            )
            nav.tabBarItem = item
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
        a.backgroundColor = UIColor(white: 0.05, alpha: 1)
        a.titleTextAttributes = [.foregroundColor: BarberTheme.gold,
                                 .font: UIFont.systemFont(ofSize: 18, weight: .bold)]
        a.largeTitleTextAttributes = [.foregroundColor: BarberTheme.gold,
                                      .font: UIFont.systemFont(ofSize: 32, weight: .heavy)]
        nav.navigationBar.standardAppearance = a
        nav.navigationBar.scrollEdgeAppearance = a
        nav.navigationBar.compactAppearance = a
        nav.navigationBar.isTranslucent = false
        nav.navigationBar.tintColor = BarberTheme.gold
        nav.navigationBar.prefersLargeTitles = true
    }

    private func styleTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(white: 0.08, alpha: 1)
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = BarberTheme.gold
        tabBar.unselectedItemTintColor = BarberTheme.textMuted
        tabBar.isTranslucent = false
        tabBar.barTintColor = BarberTheme.surface
    }

    @objc private func openSettings() {
        let nav = UINavigationController(rootViewController: SettingsViewController())
        styleNav(nav)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }
}
