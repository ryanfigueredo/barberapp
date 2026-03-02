// BarberApp — Modelo de mensagem do chat

import Foundation

struct ChatMessage {
    let id: String
    let text: String
    let isAttendant: Bool
    let timestamp: Date
    var status: String // "sending" | "sent" | "read"
}
