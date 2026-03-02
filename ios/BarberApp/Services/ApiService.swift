// BarberApp — Chamadas à API (app + admin)

import Foundation

struct ApiService {

    static let shared = ApiService()

    private var baseURL: String { AuthService.shared.baseURL }
    private var apiKey: String { AuthService.shared.apiKey }

    private init() {}

    private func request<T: Decodable>(path: String, method: String = "GET", body: Data? = nil) async throws -> T {
        guard let url = URL(string: baseURL + path) else { throw ApiError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body

        let (data, res) = try await URLSession.shared.data(for: req)
        guard let http = res as? HTTPURLResponse else { throw ApiError.noResponse }
        guard (200...299).contains(http.statusCode) else {
            if let err = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw ApiError.server(err.error)
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

struct ErrorResponse: Decodable { let error: String }

struct MonthAppointmentsResponse: Decodable {
    let month: String
    let days_with_appointments: [String: DayCount]?
    struct DayCount: Decodable {
        let count: Int?
        let statuses: [String]?
    }
}

enum ApiError: Error {
    case invalidURL
    case noResponse
    case status(Int)
    case server(String)
}
