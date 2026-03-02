//
//  NewAppointmentViewController.swift
//  BarberApp
//
//  Formulário completo para novo agendamento.
//

import UIKit

class NewAppointmentViewController: UIViewController {

    // MARK: - State
    private var selectedBarberId: String?
    private var selectedServiceId: String?
    private var selectedDate = Date()
    private var selectedSlotId: String?
    private var barbers: [BarberInfo] = []
    private var services: [ServiceInfo] = []
    private var slots: [Slot] = []

    // MARK: - UI
    private let scrollView   = UIScrollView()
    private let contentStack = UIStackView()
    private let saveButton   = UIButton()

    // Form fields
    private let nameField    = FormTextField(placeholder: "Nome do cliente", icon: "person.fill")
    private let phoneField   = FormTextField(placeholder: "WhatsApp (ex: 11999998888)", icon: "phone.fill")
    private let notesField   = FormTextField(placeholder: "Observações (opcional)", icon: "note.text")

    // Pickers
    private let barberPicker   = FormPicker(title: "Barbeiro", icon: "person.2.fill")
    private let servicePicker  = FormPicker(title: "Serviço", icon: "scissors")
    private let datePicker     = FormDatePicker(title: "Data")
    private let slotPicker     = FormPicker(title: "Horário", icon: "clock.fill")

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Novo Agendamento"
        view.backgroundColor = BarberTheme.bg
        navigationItem.leftBarButtonItem  = UIBarButtonItem(title: "Cancelar", style: .plain, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Salvar",   style: .done,  target: self, action: #selector(save))
        navigationItem.leftBarButtonItem?.tintColor  = BarberTheme.textSecond
        navigationItem.rightBarButtonItem?.tintColor = BarberTheme.gold
        setupForm()
        loadBarbers()
        loadServices()
        phoneField.keyboardType = .phonePad
    }

    // MARK: - Setup
    private func setupForm() {
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        contentStack.axis    = .vertical
        contentStack.spacing = 12
        contentStack.layoutMargins = UIEdgeInsets(top: 20, left: 16, bottom: 32, right: 16)
        contentStack.isLayoutMarginsRelativeArrangement = true
        scrollView.addSubview(contentStack)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
        ])

        // Section: Cliente
        contentStack.addArrangedSubview(sectionHeader("Cliente"))
        contentStack.addArrangedSubview(nameField)
        contentStack.addArrangedSubview(phoneField)

        // Section: Agendamento
        contentStack.addArrangedSubview(sectionHeader("Agendamento"))
        contentStack.addArrangedSubview(barberPicker)
        contentStack.addArrangedSubview(servicePicker)
        contentStack.addArrangedSubview(datePicker)
        contentStack.addArrangedSubview(slotPicker)

        // Section: Observações
        contentStack.addArrangedSubview(sectionHeader("Observações"))
        contentStack.addArrangedSubview(notesField)

        // Save button
        saveButton.setTitle("Confirmar Agendamento", for: .normal)
        saveButton.backgroundColor = BarberTheme.gold
        saveButton.setTitleColor(.black, for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        saveButton.layer.cornerRadius = 14
        saveButton.layer.cornerCurve  = .continuous
        saveButton.heightAnchor.constraint(equalToConstant: 54).isActive = true
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        contentStack.addArrangedSubview(UIView())
        contentStack.addArrangedSubview(saveButton)

        barberPicker.onTap  = { [weak self] in self?.showBarberPicker() }
        servicePicker.onTap = { [weak self] in self?.showServicePicker() }
        datePicker.onDateChanged = { [weak self] date in
            self?.selectedDate = date
            self?.loadSlots()
        }
        slotPicker.onTap = { [weak self] in self?.showSlotPicker() }
    }

    private func sectionHeader(_ title: String) -> UIView {
        let lbl = UILabel()
        lbl.text      = title.uppercased()
        lbl.font      = .systemFont(ofSize: 11, weight: .semibold)
        lbl.textColor = BarberTheme.textMuted
        let v = UIView()
        v.addSubview(lbl)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lbl.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 4),
            lbl.topAnchor.constraint(equalTo: v.topAnchor, constant: 8),
            lbl.bottomAnchor.constraint(equalTo: v.bottomAnchor),
        ])
        v.heightAnchor.constraint(equalToConstant: 28).isActive = true
        return v
    }

    // MARK: - API
    private func loadBarbers() {
        ApiService.shared.getBarbers { [weak self] result in
            DispatchQueue.main.async {
                if case .success(let list) = result {
                    self?.barbers = list
                    self?.barberPicker.setPlaceholder("Selecionar barbeiro")
                }
            }
        }
    }

    private func loadServices() {
        ApiService.shared.fetch("/api/admin/services") { [weak self] (result: Result<[ServiceInfo], Error>) in
            DispatchQueue.main.async {
                if case .success(let list) = result {
                    self?.services = list
                    self?.servicePicker.setPlaceholder("Selecionar serviço")
                }
            }
        }
    }

    private func loadSlots() {
        guard let barberId = selectedBarberId else { return }
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let dateStr = fmt.string(from: selectedDate)
        ApiService.shared.fetch("/api/app/slots/available?date=\(dateStr)&barber_id=\(barberId)") { [weak self] (result: Result<SlotsResponse, Error>) in
            DispatchQueue.main.async {
                if case .success(let resp) = result {
                    self?.slots = resp.slots
                    self?.slotPicker.setPlaceholder(resp.slots.isEmpty ? "Sem horários disponíveis" : "Selecionar horário")
                }
            }
        }
    }

    // MARK: - Pickers
    private func showBarberPicker() {
        let alert = UIAlertController(title: "Escolher Barbeiro", message: nil, preferredStyle: .actionSheet)
        barbers.forEach { barber in
            alert.addAction(UIAlertAction(title: barber.name, style: .default) { [weak self] _ in
                self?.selectedBarberId = barber.id
                self?.barberPicker.setValue(barber.name)
                self?.loadSlots()
            })
        }
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    private func showServicePicker() {
        let alert = UIAlertController(title: "Escolher Serviço", message: nil, preferredStyle: .actionSheet)
        services.forEach { service in
            let title = "\(service.name) — R$\(String(format: "%.0f", service.price))"
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.selectedServiceId = service.id
                self?.servicePicker.setValue(service.name)
            })
        }
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    private func showSlotPicker() {
        guard !slots.isEmpty else {
            showError("Selecione um barbeiro e uma data primeiro")
            return
        }
        let alert = UIAlertController(title: "Escolher Horário", message: nil, preferredStyle: .actionSheet)
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm"
        let iso = ISO8601DateFormatter()
        slots.forEach { slot in
            let start = iso.date(from: slot.startTime).map { timeFmt.string(from: $0) } ?? slot.startTime
            let end   = iso.date(from: slot.endTime).map { timeFmt.string(from: $0) } ?? slot.endTime
            alert.addAction(UIAlertAction(title: "\(start) – \(end)", style: .default) { [weak self] _ in
                self?.selectedSlotId = slot.id
                self?.slotPicker.setValue("\(start) – \(end)")
            })
        }
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Save
    @objc private func save() {
        guard let name = nameField.text, !name.isEmpty else { showError("Informe o nome do cliente"); return }
        guard let phone = phoneField.text, !phone.isEmpty else { showError("Informe o WhatsApp"); return }
        guard let barberId = selectedBarberId else { showError("Selecione um barbeiro"); return }

        saveButton.setTitle("Salvando...", for: .normal)
        saveButton.isEnabled = false

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"
        dateFmt.timeZone = TimeZone(identifier: "UTC")
        let dateStr = dateFmt.string(from: selectedDate)

        var body: [String: Any] = [
            "customer_name":     name,
            "customer_phone":    phone.filter("0123456789".contains),
            "barber_id":         barberId,
            "appointment_date":  dateStr + "T12:00:00.000Z",
            "origin":            "app",
        ]
        if let sid = selectedServiceId  { body["service_id"]  = sid }
        if let slot = selectedSlotId   { body["slot_id"]      = slot }
        if let notes = notesField.text, !notes.isEmpty { body["customer_notes"] = notes }

        ApiService.shared.post("/api/app/appointments", body: body) { [weak self] result in
            DispatchQueue.main.async {
                self?.saveButton.setTitle("Confirmar Agendamento", for: .normal)
                self?.saveButton.isEnabled = true
                switch result {
                case .success:
                    self?.dismiss(animated: true)
                    NotificationCenter.default.post(name: .appointmentCreated, object: nil)
                case .failure(let err):
                    self?.showError(err.localizedDescription)
                }
            }
        }
    }

    private func showError(_ msg: String) {
        let alert = UIAlertController(title: "Atenção", message: msg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func cancel() { dismiss(animated: true) }
}

// MARK: - Form components

final class FormTextField: UIView {
    var text: String? { textField.text }
    var keyboardType: UIKeyboardType = .default { didSet { textField.keyboardType = keyboardType } }
    private let textField = UITextField()

    init(placeholder: String, icon: String) {
        super.init(frame: .zero)
        backgroundColor = BarberTheme.surface
        layer.cornerRadius = 12
        layer.cornerCurve  = .continuous
        layer.borderWidth  = 1
        layer.borderColor  = BarberTheme.border.cgColor
        heightAnchor.constraint(equalToConstant: 52).isActive = true

        let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: icon, withConfiguration: cfg))
        iconView.tintColor = BarberTheme.textMuted
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 20).isActive = true

        textField.placeholder = placeholder
        textField.font        = .systemFont(ofSize: 15)
        textField.textColor   = BarberTheme.textPrimary
        textField.tintColor   = BarberTheme.gold
        let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: BarberTheme.textMuted]
        textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: attrs)

        let stack = UIStackView(arrangedSubviews: [iconView, textField])
        stack.spacing = 10
        stack.alignment = .center
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class FormPicker: UIView {
    var onTap: (() -> Void)?
    private let valueLabel = UILabel()
    private let chevron    = UIImageView()

    init(title: String, icon: String) {
        super.init(frame: .zero)
        backgroundColor = BarberTheme.surface
        layer.cornerRadius = 12
        layer.cornerCurve  = .continuous
        layer.borderWidth  = 1
        layer.borderColor  = BarberTheme.border.cgColor
        heightAnchor.constraint(equalToConstant: 52).isActive = true

        let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: icon, withConfiguration: cfg))
        iconView.tintColor   = BarberTheme.textMuted
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 20).isActive = true

        valueLabel.text      = "Selecionar..."
        valueLabel.font      = .systemFont(ofSize: 15)
        valueLabel.textColor = BarberTheme.textMuted

        chevron.image    = UIImage(systemName: "chevron.right", withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .medium))
        chevron.tintColor = BarberTheme.textMuted
        chevron.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [iconView, valueLabel, UIView(), chevron])
        stack.spacing   = 10
        stack.alignment = .center
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setValue(_ value: String) {
        valueLabel.text      = value
        valueLabel.textColor = BarberTheme.textPrimary
    }
    func setPlaceholder(_ text: String) {
        if valueLabel.textColor == BarberTheme.textMuted { valueLabel.text = text }
    }

    @objc private func tapped() {
        UIView.animate(withDuration: 0.08, animations: { self.alpha = 0.6 }) { _ in
            UIView.animate(withDuration: 0.15) { self.alpha = 1 }
        }
        onTap?()
    }
}

final class FormDatePicker: UIView {
    var onDateChanged: ((Date) -> Void)?
    private let picker = UIDatePicker()
    private let label  = UILabel()

    init(title: String) {
        super.init(frame: .zero)
        backgroundColor = BarberTheme.surface
        layer.cornerRadius = 12
        layer.cornerCurve  = .continuous
        layer.borderWidth  = 1
        layer.borderColor  = BarberTheme.border.cgColor

        picker.datePickerMode    = .date
        picker.preferredDatePickerStyle = .compact
        picker.minimumDate       = Date()
        picker.tintColor         = BarberTheme.gold
        picker.overrideUserInterfaceStyle = .dark
        picker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)

        label.text      = "Data"
        label.font      = .systemFont(ofSize: 15)
        label.textColor = BarberTheme.textPrimary

        let cfg = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let iconView = UIImageView(image: UIImage(systemName: "calendar", withConfiguration: cfg))
        iconView.tintColor   = BarberTheme.textMuted
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 20).isActive = true

        let stack = UIStackView(arrangedSubviews: [iconView, label, UIView(), picker])
        stack.spacing   = 10
        stack.alignment = .center
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        heightAnchor.constraint(equalToConstant: 52).isActive = true
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func dateChanged() { onDateChanged?(picker.date) }
}
