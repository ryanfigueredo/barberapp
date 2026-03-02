//
//  NewAppointmentViewController.swift
//  BarberApp
//

import UIKit

class NewAppointmentViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BarberTheme.bg
        title = "Novo agendamento"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissSelf))
        navigationItem.leftBarButtonItem?.tintColor = BarberTheme.gold

        let lbl = UILabel()
        lbl.text = "Em breve: formulário de novo agendamento"
        lbl.textColor = BarberTheme.textMuted
        lbl.textAlignment = .center
        lbl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lbl)
        NSLayoutConstraint.activate([
            lbl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            lbl.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}
