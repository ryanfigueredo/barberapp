//
//  ContentView.swift
//  BarberApp
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        RootView()
            .preferredColorScheme(.dark)
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
