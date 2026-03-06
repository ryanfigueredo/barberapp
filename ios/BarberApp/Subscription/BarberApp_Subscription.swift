//
//  BarberApp_Subscription.swift
//  BarberApp
//
//  SubscriptionManager (StoreKit 2), OnboardingView, PaywallView, TrialBannerView.
//  Produto App Store Connect: com.barberapp.monthly — R$ 129/mês.
//

import SwiftUI
import StoreKit

// MARK: - Subscription Status
enum SubscriptionStatus {
    case trial(daysRemaining: Int)
    case active
    case expired
    case none
}

// MARK: - Subscription Manager
@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var status: SubscriptionStatus = .none
    @Published var isLoading = false

    private let productID = "com.barberapp.monthly"
    private let trialDays = 14
    private let trialStartKey = "trial_start_date"
    private let subscribedKey = "is_subscribed"

    init() {
        Task { await refreshStatus() }
    }

    func refreshStatus() async {
        isLoading = true
        defer { isLoading = false }

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == productID,
               transaction.revocationDate == nil {
                status = .active
                return
            }
        }

        if let start = UserDefaults.standard.object(forKey: trialStartKey) as? Date {
            let daysPassed = Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
            let remaining = trialDays - daysPassed
            if remaining > 0 {
                status = .trial(daysRemaining: remaining)
            } else {
                status = .expired
            }
        } else {
            status = .none
        }
    }

    func startTrial() {
        UserDefaults.standard.set(Date(), forKey: trialStartKey)
        status = .trial(daysRemaining: trialDays)
    }

    func purchase() async throws {
        let products = try await Product.products(for: [productID])
        guard let product = products.first else { return }
        let result = try await product.purchase()
        if case .success = result {
            await refreshStatus()
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshStatus()
    }

    var isBlocked: Bool {
        if case .expired = status { return true }
        return false
    }

    var trialBadge: String? {
        if case .trial(let days) = status {
            return days == 1 ? "Último dia de trial!" : "\(days) dias grátis"
        }
        return nil
    }
}

// MARK: - Onboarding Flow
enum OnboardingStep {
    case businessType
    case trialIntro
    case ready
}

struct OnboardingView: View {
    @StateObject private var sub = SubscriptionManager.shared
    @State private var step: OnboardingStep = .businessType
    @State private var selectedType: BusinessType? = nil

    var onComplete: () -> Void

    enum BusinessType: String, CaseIterable {
        case studio = "Studio Solo"
        case commission = "Barbeiro Comissionado"
        case shopOwner = "Dono de Barbearia"
        case apprentice = "Aprendiz / Estudante"

        var icon: String {
            switch self {
            case .studio: return "chair.lounge"
            case .commission: return "person.fill"
            case .shopOwner: return "storefront"
            case .apprentice: return "graduationcap"
            }
        }

        var subtitle: String {
            switch self {
            case .studio: return "Trabalho solo por conta própria"
            case .commission: return "Trabalho em uma barbearia existente"
            case .shopOwner: return "Gerencio uma equipe de barbeiros"
            case .apprentice: return "Ainda estou aprendendo a profissão"
            }
        }
    }

    var body: some View {
        ZStack {
            BarberDesignSystem.background.ignoresSafeArea()

            switch step {
            case .businessType:
                businessTypeView
            case .trialIntro:
                trialIntroView
            case .ready:
                Color.clear.onAppear { onComplete() }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: step)
    }

    var businessTypeView: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Como você\ntrabalha?")
                    .font(BarberDesignSystem.titleLarge())
                    .foregroundColor(BarberDesignSystem.textPrimary)
                    .padding(.top, 60)
                    .padding(.horizontal, 28)

                Text("Escolha a opção que melhor te descreve")
                    .font(BarberDesignSystem.bodySmall())
                    .foregroundColor(BarberDesignSystem.textSecondary)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 32)
            }

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(OnboardingView.BusinessType.allCases, id: \.self) { type in
                        BusinessTypeCard(
                            type: type,
                            isSelected: selectedType == type
                        ) {
                            selectedType = type
                        }
                    }
                }
                .padding(.horizontal, 20)
            }

            Spacer()

            Button {
                guard selectedType != nil else { return }
                withAnimation { step = .trialIntro }
            } label: {
                Text("Continuar")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(selectedType != nil ? .black : BarberDesignSystem.textMuted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        selectedType != nil
                        ? BarberDesignSystem.gold
                        : BarberDesignSystem.cardHighlight
                    )
                    .cornerRadius(BarberDesignSystem.cornerRadius)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
            .disabled(selectedType == nil)
        }
    }

    var trialIntroView: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(BarberDesignSystem.goldOpacity12)
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(BarberDesignSystem.gold)
            }
            .padding(.bottom, 28)

            Text("14 dias grátis")
                .font(.system(size: 34, weight: .black))
                .foregroundColor(BarberDesignSystem.textPrimary)

            Text("Explore tudo sem precisar de cartão.\nAssine quando quiser durante o trial.")
                .font(BarberDesignSystem.body())
                .foregroundColor(BarberDesignSystem.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 12)

            Spacer()

            VStack(alignment: .leading, spacing: 0) {
                Text("O QUE VEM A SEGUIR")
                    .font(BarberDesignSystem.overline())
                    .foregroundColor(BarberDesignSystem.textMuted)
                    .tracking(2)
                    .padding(.bottom, 16)

                ChecklistItem(icon: "calendar", text: "Configure seus horários")
                ChecklistItem(icon: "scissors", text: "Adicione seus serviços e barbeiros")
                ChecklistItem(icon: "message.fill", text: "Conecte seu WhatsApp Business")
                ChecklistItem(icon: "bell.fill", text: "Receba alertas de novos agendamentos")
            }
            .padding(24)
            .background(BarberDesignSystem.card)
            .cornerRadius(18)
            .padding(.horizontal, 20)

            Spacer()

            Button {
                sub.startTrial()
                withAnimation { step = .ready }
            } label: {
                Text("Começar agora — é grátis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(BarberDesignSystem.gold)
                    .cornerRadius(BarberDesignSystem.cornerRadius)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Business Type Card
struct BusinessTypeCard: View {
    let type: OnboardingView.BusinessType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? BarberDesignSystem.goldOpacity12 : BarberDesignSystem.card)
                        .frame(width: 46, height: 46)
                    Image(systemName: type.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? BarberDesignSystem.gold : BarberDesignSystem.textSecondary)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(type.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(BarberDesignSystem.textPrimary)
                    Text(type.subtitle)
                        .font(BarberDesignSystem.bodySmall())
                        .foregroundColor(BarberDesignSystem.textSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "chevron.right")
                    .foregroundColor(isSelected ? BarberDesignSystem.gold : BarberDesignSystem.textMuted)
                    .font(.system(size: isSelected ? 20 : 14))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: BarberDesignSystem.cornerRadius)
                    .fill(isSelected ? BarberDesignSystem.cardHighlight : BarberDesignSystem.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: BarberDesignSystem.cornerRadius)
                            .strokeBorder(isSelected ? BarberDesignSystem.borderGold : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Checklist Item
struct ChecklistItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(BarberDesignSystem.gold)
                .frame(width: 20)
            Text(text)
                .font(BarberDesignSystem.bodySmall())
                .foregroundColor(BarberDesignSystem.textPrimary.opacity(0.75))
            Spacer()
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Paywall (Trial Expired)
struct PaywallView: View {
    @StateObject private var sub = SubscriptionManager.shared
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            BarberDesignSystem.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle().fill(BarberDesignSystem.goldOpacity12).frame(width: 90, height: 90)
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 36))
                        .foregroundColor(BarberDesignSystem.gold)
                }
                .padding(.bottom, 24)

                Text("Seu trial expirou")
                    .font(BarberDesignSystem.titleMedium())
                    .foregroundColor(BarberDesignSystem.textPrimary)

                Text("Continue gerenciando sua barbearia\ncom o plano mensal.")
                    .font(BarberDesignSystem.body())
                    .foregroundColor(BarberDesignSystem.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 10)

                Spacer()

                VStack(spacing: 8) {
                    Text("R$ 129")
                        .font(.system(size: 48, weight: .black))
                        .foregroundColor(BarberDesignSystem.textPrimary)
                    Text("por mês · cancele quando quiser")
                        .font(.system(size: 13))
                        .foregroundColor(BarberDesignSystem.textMuted)
                }
                .padding(.vertical, 28)

                VStack(spacing: 0) {
                    FeatureRow(icon: "message.fill", text: "Bot WhatsApp ilimitado")
                    Divider().background(BarberDesignSystem.border)
                    FeatureRow(icon: "calendar", text: "Agendamentos e calendário")
                    Divider().background(BarberDesignSystem.border)
                    FeatureRow(icon: "bell.fill", text: "Alertas de novos clientes")
                    Divider().background(BarberDesignSystem.border)
                    FeatureRow(icon: "person.2.fill", text: "Gestão de barbeiros e serviços")
                }
                .background(BarberDesignSystem.card)
                .cornerRadius(BarberDesignSystem.cornerRadius)
                .padding(.horizontal, 20)

                Spacer()

                if let error = errorMessage {
                    Text(error)
                        .font(BarberDesignSystem.caption())
                        .foregroundColor(.red.opacity(0.8))
                        .padding(.bottom, 8)
                }

                Button {
                    Task {
                        isPurchasing = true
                        errorMessage = nil
                        do {
                            try await sub.purchase()
                        } catch {
                            errorMessage = "Não foi possível processar. Tente novamente."
                        }
                        isPurchasing = false
                    }
                } label: {
                    Group {
                        if isPurchasing {
                            ProgressView().tint(.black)
                        } else {
                            Text("Assinar agora")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(BarberDesignSystem.gold)
                    .cornerRadius(BarberDesignSystem.cornerRadius)
                }
                .padding(.horizontal, 20)
                .disabled(isPurchasing)

                Button {
                    Task { await sub.restorePurchases() }
                } label: {
                    Text("Restaurar compras")
                        .font(.system(size: 13))
                        .foregroundColor(BarberDesignSystem.textMuted)
                }
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(BarberDesignSystem.gold)
                .frame(width: 24)
            Text(text)
                .font(BarberDesignSystem.bodySmall())
                .foregroundColor(BarberDesignSystem.textPrimary.opacity(0.8))
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(BarberDesignSystem.gold)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}

// MARK: - Trial Banner (Dashboard)
struct TrialBannerView: View {
    @StateObject private var sub = SubscriptionManager.shared
    @State private var showPaywall = false

    var body: some View {
        if let badge = sub.trialBadge {
            HStack(spacing: 10) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.black)
                Text(badge)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black)
                Spacer()
                Button("Assinar") {
                    showPaywall = true
                }
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.black)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(BarberDesignSystem.gold)
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }
}

// MARK: - Previews
#Preview("Onboarding") { OnboardingView(onComplete: {}) }
#Preview("Paywall") { PaywallView() }
