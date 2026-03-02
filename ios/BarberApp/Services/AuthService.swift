// BarberApp — Autenticação (login por usuário/senha → api_key + barber_id)
// Produção: https://barberapp-rust.vercel.app
// Cada barbeiro entra com seu login; admin vê tudo, barber vê só o seu.

import Foundation

final class AuthService {
    static let shared = AuthService()

    static let productionBaseURL = "https://barberapp-rust.vercel.app"

    private let apiKeyKey = "barberapp_api_key"
    private let baseURLKey = "barberapp_base_url"
    private let barberIdKey = "barberapp_barber_id"
    private let roleKey = "barberapp_role"
    private let userNameKey = "barberapp_user_name"
    private let tenantNameKey = "barberapp_tenant_name"

    var apiKey: String {
        get { UserDefaults.standard.string(forKey: apiKeyKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: apiKeyKey) }
    }

    var baseURL: String {
        get { UserDefaults.standard.string(forKey: baseURLKey) ?? Self.productionBaseURL }
        set { UserDefaults.standard.set(newValue, forKey: baseURLKey) }
    }

    /// Barbeiro logado: quando preenchido, as requisições enviam X-Barber-Id e o backend filtra só os dados dele.
    var barberId: String? {
        get { UserDefaults.standard.string(forKey: barberIdKey) }
        set { UserDefaults.standard.set(newValue, forKey: barberIdKey) }
    }

    /// admin = vê tudo da barbearia; barber = vê só o seu.
    var role: String {
        get { UserDefaults.standard.string(forKey: roleKey) ?? "admin" }
        set { UserDefaults.standard.set(newValue, forKey: roleKey) }
    }

    var userName: String? {
        get { UserDefaults.standard.string(forKey: userNameKey) }
        set { UserDefaults.standard.set(newValue, forKey: userNameKey) }
    }

    var tenantName: String? {
        get { UserDefaults.standard.string(forKey: tenantNameKey) }
        set { UserDefaults.standard.set(newValue, forKey: tenantNameKey) }
    }

    var isLoggedIn: Bool {
        !apiKey.isEmpty
    }

    var isAdmin: Bool {
        role == "admin" || role == "owner" || role == "super_admin"
    }

    func logout() {
        apiKey = ""
        barberId = nil
        role = "admin"
        userName = nil
        tenantName = nil
    }

    private init() {}
}
