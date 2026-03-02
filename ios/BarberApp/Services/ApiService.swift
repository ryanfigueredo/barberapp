// BarberApp — Chamadas à API (app + admin)

import Foundation

struct ApiService {

    static let shared = ApiService()

    private var baseURL: String { AuthService.shared.baseURL }
    private var apiKey: String { AuthService.shared.apiKey }

    private init() {}

    private static func parseErrorString(from data: Data) -> String? {
        (try? JSONSerialization.jsonObject(with: data) as? [String: Any])?["error"] as? String
    }

    // MARK: - Generic fetch (callback) para uso em Calendar, Appointments, etc.
    func fetch<T: Decodable>(_ path: String, completion: @escaping (Result<T, Error>) -> Void) {
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(ApiError.invalidURL))
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        if let barberId = AuthService.shared.barberId {
            req.setValue(barberId, forHTTPHeaderField: "X-Barber-Id")
        }

        URLSession.shared.dataTask(with: req) { data, res, err in
            if let err = err {
                DispatchQueue.main.async { completion(.failure(err)) }
                return
            }
            guard let http = res as? HTTPURLResponse else {
                DispatchQueue.main.async { completion(.failure(ApiError.noResponse)) }
                return
            }
            guard (200...299).contains(http.statusCode), let data = data else {
                if let data = data, let msg = Self.parseErrorString(from: data) {
                    DispatchQueue.main.async { completion(.failure(ApiError.server(msg))) }
                } else {
                    DispatchQueue.main.async { completion(.failure(ApiError.status(http.statusCode))) }
                }
                return
            }
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                DispatchQueue.main.async { completion(.success(decoded)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(error)) }
            }
        }.resume()
    }

    // MARK: - POST genérico (criar agendamento, etc.)
    func post(_ path: String, body: [String: Any], completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: baseURL + path) else {
            completion(.failure(ApiError.invalidURL))
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        if let barberId = AuthService.shared.barberId {
            req.setValue(barberId, forHTTPHeaderField: "X-Barber-Id")
        }
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        guard let data = try? JSONSerialization.data(withJSONObject: body) else {
            completion(.failure(ApiError.invalidURL))
            return
        }
        req.httpBody = data

        URLSession.shared.dataTask(with: req) { data, res, err in
            if let err = err {
                DispatchQueue.main.async { completion(.failure(err)) }
                return
            }
            guard let http = res as? HTTPURLResponse else {
                DispatchQueue.main.async { completion(.failure(ApiError.noResponse)) }
                return
            }
            guard (200...299).contains(http.statusCode) else {
                if let data = data, let msg = Self.parseErrorString(from: data) {
                    DispatchQueue.main.async { completion(.failure(ApiError.server(msg))) }
                } else {
                    DispatchQueue.main.async { completion(.failure(ApiError.status(http.statusCode))) }
                }
                return
            }
            DispatchQueue.main.async { completion(.success(data ?? Data())) }
        }.resume()
    }

    // MARK: - Tenant profile
    func getTenantProfile(completion: @escaping (Result<TenantProfile, Error>) -> Void) {
        fetch("/api/admin/tenant-profile", completion: completion)
    }

    func updateTenantProfile(_ fields: [String: String], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/api/admin/tenant-profile") else {
            completion(.failure(ApiError.invalidURL))
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        if let barberId = AuthService.shared.barberId {
            req.setValue(barberId, forHTTPHeaderField: "X-Barber-Id")
        }
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = (try? JSONSerialization.data(withJSONObject: fields))

        URLSession.shared.dataTask(with: req) { _, res, err in
            if let err = err {
                DispatchQueue.main.async { completion(.failure(err)) }
                return
            }
            guard let http = res as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                DispatchQueue.main.async { completion(.failure(ApiError.status((res as? HTTPURLResponse)?.statusCode ?? 500))) }
                return
            }
            DispatchQueue.main.async { completion(.success(())) }
        }.resume()
    }

    // MARK: - Appointment status
    func updateAppointmentStatus(id: String, status: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: baseURL + "/api/app/appointments/\(id)/status") else {
            completion(.failure(ApiError.invalidURL))
            return
        }
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        if let barberId = AuthService.shared.barberId {
            req.setValue(barberId, forHTTPHeaderField: "X-Barber-Id")
        }
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = (try? JSONEncoder().encode(["status": status]))

        URLSession.shared.dataTask(with: req) { _, res, err in
            if let err = err {
                DispatchQueue.main.async { completion(.failure(err)) }
                return
            }
            guard let http = res as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                DispatchQueue.main.async { completion(.failure(ApiError.status((res as? HTTPURLResponse)?.statusCode ?? 500))) }
                return
            }
            DispatchQueue.main.async { completion(.success(())) }
        }.resume()
    }

    // MARK: - Barbers (callback para BarberFilterBar)
    func getBarbers(completion: @escaping (Result<[BarberInfo], Error>) -> Void) {
        fetch("/api/app/barbers", completion: completion)
    }

    // MARK: - Login (sem auth — usa baseURL do AuthService)
    func login(username: String, password: String) async throws -> MobileLoginResponse {
        guard let url = URL(string: baseURL + "/api/auth/mobile-login") else { throw ApiError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["username": username, "password": password]
        req.httpBody = try JSONEncoder().encode(body)

        let (data, res) = try await URLSession.shared.data(for: req)
        guard let http = res as? HTTPURLResponse else { throw ApiError.noResponse }
        guard (200...299).contains(http.statusCode) else {
            if let msg = Self.parseErrorString(from: data) {
                throw ApiError.server(msg)
            }
            throw ApiError.status(http.statusCode)
        }
        return try JSONDecoder().decode(MobileLoginResponse.self, from: data)
    }

    private func request<T: Decodable>(path: String, method: String = "GET", body: Data? = nil) async throws -> T {
        guard let url = URL(string: baseURL + path) else { throw ApiError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        if let barberId = AuthService.shared.barberId {
            req.setValue(barberId, forHTTPHeaderField: "X-Barber-Id")
        }
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body

        let (data, res) = try await URLSession.shared.data(for: req)
        guard let http = res as? HTTPURLResponse else { throw ApiError.noResponse }
        guard (200...299).contains(http.statusCode) else {
            if let msg = Self.parseErrorString(from: data) {
                throw ApiError.server(msg)
            }
            throw ApiError.status(http.statusCode)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Appointments
    func getAppointments(date: String, barberId: String? = nil) async throws -> AppointmentsResponse {
        var path = "/api/app/appointments?date=\(date)"
        if let id = barberId { path += "&barber_id=\(id)" }
        return try await request(path: path)
    }

    func getAppointmentsUpcoming() async throws -> AppointmentsResponse {
        try await request(path: "/api/app/appointments?upcoming=true")
    }

    func getAppointmentsMonth(month: String) async throws -> MonthAppointmentsResponse {
        try await request(path: "/api/app/appointments/month?month=\(month)")
    }

    // MARK: - Barbers
    func getBarbers() async throws -> [BarberInfo] {
        try await request(path: "/api/app/barbers")
    }

    // MARK: - Services
    func getServices() async throws -> [ServiceInfo] {
        try await request(path: "/api/admin/services")
    }

    // MARK: - Conversations / Mensagens (quando o backend tiver endpoint)
    func getPriorityConversations(completion: @escaping (Result<[Conversation], Error>) -> Void) {
        // TODO: GET /api/admin/conversations ou similar
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            completion(.success([]))
        }
    }

    func getConversationHistory(phone: String, completion: @escaping (Result<[ChatMessage], Error>) -> Void) {
        // TODO: GET /api/admin/conversations/\(phone)/messages
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            completion(.success([]))
        }
    }

    func sendWhatsAppMessage(phone: String, message: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // TODO: POST enviar mensagem via API
        completion(.success(()))
    }
}


struct AppointmentsResponse: Decodable {
    let appointments: [Appointment]
}

struct TenantProfile: Decodable {
    let id: String
    let name: String
    let slug: String?
    let business_name: String?
    let logo_url: String?
    let address: String?
    let opening_time: String?
    let closing_time: String?
    let slot_duration_minutes: Int?
    let whatsapp_phone: String?
    let bot_configured: Bool?
    let plan_type: String?
    let plan_active: Bool?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, address, plan_type, plan_active
        case business_name, logo_url, opening_time, closing_time
        case slot_duration_minutes, whatsapp_phone, bot_configured
    }
}

struct MobileLoginResponse: Decodable {
    let success: Bool
    let api_key: String
    let tenant: TenantInfo?
    let user: UserInfo?
    struct TenantInfo: Decodable {
        let id: String
        let name: String
        let slug: String?
    }
    struct UserInfo: Decodable {
        let id: String
        let username: String?
        let name: String
        let role: String
        let barber_id: String?
        let barber: BarberRef?
        struct BarberRef: Decodable {
            let id: String
            let name: String
        }
    }
}

struct MonthAppointmentsResponse: Decodable {
    let month: String
    let days_with_appointments: [String: DayCount]?
    struct DayCount: Decodable {
        let count: Int?
        let statuses: [String]?
    }
}

struct SlotsResponse: Decodable {
    let slots: [Slot]
}

struct Slot: Decodable {
    let id: String
    let startTime: String
    let endTime: String
    let time: String?
    let barber: BarberInfo?

    enum CodingKeys: String, CodingKey {
        case id, time, barber
        case startTime = "start_time"
        case endTime = "end_time"
    }
}

struct DashboardStats: Decodable {
    let today: Int
    let week: Int
    let barbers: Int
    let revenue_today: Double?
    let revenue_week: Double?
    let upcoming_today: [UpcomingAppointmentItem]
}

struct UpcomingAppointmentItem: Decodable {
    let id: String
    let customer_name: String
    let appointment_date: String
    let status: String
    let barber: BarberInfo
    let service: ServiceInfoShort?
}

struct ServiceInfoShort: Decodable {
    let id: String
    let name: String
    let price: Double?
}

enum ApiError: Error {
    case invalidURL
    case noResponse
    case status(Int)
    case server(String)
}
