// BarberApp — Autenticação (api_key + baseURL)

import Foundation

final class AuthService {
    static let shared = AuthService()

    private let apiKeyKey = "barberapp_api_key"
    private let baseURLKey = "barberapp_base_url"

    var apiKey: String {
        get { UserDefaults.standard.string(forKey: apiKeyKey) ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: apiKeyKey) }
    }

    var baseURL: String {
        get { UserDefaults.standard.string(forKey: baseURLKey) ?? "http://localhost:3000" }
        set { UserDefaults.standard.set(newValue, forKey: baseURLKey) }
    }

    var isLoggedIn: Bool {
        !apiKey.isEmpty
    }

    func logout() {
        apiKey = ""
    }

    private init() {}
}
