import SwiftUI

struct ContentView: View {
    @StateObject private var sub = SubscriptionManager.shared
    @State private var showSplash = true
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "onboarding_done")

    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
                .transition(.opacity)
                .zIndex(10)
            } else if showOnboarding {
                OnboardingView {
                    UserDefaults.standard.set(true, forKey: "onboarding_done")
                    withAnimation { showOnboarding = false }
                }
                .transition(.opacity)
            } else if sub.isBlocked {
                PaywallView()
                    .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    TrialBannerView()
                    RootView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .background(BarberDesignSystem.background.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.35), value: showSplash)
        .animation(.easeInOut(duration: 0.35), value: showOnboarding)
        .animation(.easeInOut(duration: 0.35), value: sub.isBlocked)
    }
}

/// Entry: não logado → LoginViewController; logado → MainTabViewController
struct RootView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        if AuthService.shared.isLoggedIn {
            return MainTabViewController()
        }
        return LoginViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

#Preview {
    ContentView()
}
