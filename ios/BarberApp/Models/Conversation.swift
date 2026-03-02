// BarberApp — Modelo de conversa (inbox)

import Foundation

struct Conversation {
    let id: String
    let customerPhone: String
    let customerName: String?
    let lastMessage: String
    let lastMessageDate: Date
    let unreadCount: Int
    let isWaitingAttendant: Bool
}
