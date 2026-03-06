//
//  SplashScreenView.swift
//  BarberApp
//
//  3 ondas douradas animadas subindo, logo tesoura + spring, BARBER/APP tracking alto. 2.8s → onFinished().
//

import SwiftUI

// MARK: - Wave Shape
struct WaveShape: Shape {
    var phase: Double
    var amplitude: Double
    var frequency: Double

    var animatableData: Double {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midY = height * 0.5

        path.move(to: CGPoint(x: 0, y: midY))

        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let y = midY + amplitude * sin(frequency * relativeX * .pi * 2 + phase)
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Animated Wave View
struct AnimatedWave: View {
    let color: Color
    let amplitude: Double
    let frequency: Double
    let speed: Double
    let yOffset: CGFloat

    @State private var phase: Double = 0

    var body: some View {
        WaveShape(phase: phase, amplitude: amplitude, frequency: frequency)
            .fill(color)
            .offset(y: yOffset)
            .onAppear {
                withAnimation(
                    .linear(duration: speed)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = .pi * 2
                }
            }
    }
}

// MARK: - Splash Screen
struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.4
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var wavesOffset: CGFloat = 300

    var onFinished: () -> Void

    var body: some View {
        ZStack {
            BarberDesignSystem.background.ignoresSafeArea()

            // Waves at bottom
            VStack {
                Spacer()
                ZStack(alignment: .bottom) {
                    AnimatedWave(
                        color: BarberDesignSystem.goldOpacity10,
                        amplitude: 22,
                        frequency: 1.2,
                        speed: 4.5,
                        yOffset: -10
                    )
                    .frame(height: 260)

                    AnimatedWave(
                        color: BarberDesignSystem.goldOpacity18,
                        amplitude: 18,
                        frequency: 1.6,
                        speed: 3.2,
                        yOffset: 18
                    )
                    .frame(height: 220)

                    AnimatedWave(
                        color: BarberDesignSystem.goldOpacity25,
                        amplitude: 14,
                        frequency: 2.0,
                        speed: 2.4,
                        yOffset: 40
                    )
                    .frame(height: 180)
                }
                .offset(y: wavesOffset)
            }
            .ignoresSafeArea()

            // Logo + title center
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(BarberDesignSystem.goldOpacity12)
                        .frame(width: 110, height: 110)

                    Circle()
                        .strokeBorder(BarberDesignSystem.goldOpacity35, lineWidth: 1.5)
                        .frame(width: 110, height: 110)

                    Image(systemName: "scissors")
                        .font(.system(size: 44, weight: .light))
                        .foregroundColor(BarberDesignSystem.gold)
                        .rotationEffect(.degrees(-45))
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                VStack(spacing: 6) {
                    Text("BARBER")
                        .font(.system(size: 36, weight: .black, design: .default))
                        .tracking(BarberDesignSystem.trackingHigh)
                        .foregroundColor(BarberDesignSystem.textPrimary)

                    Text("APP")
                        .font(.system(size: 36, weight: .ultraLight, design: .default))
                        .tracking(BarberDesignSystem.trackingHigh)
                        .foregroundColor(BarberDesignSystem.gold)

                    Rectangle()
                        .fill(BarberDesignSystem.gold.opacity(0.5))
                        .frame(width: 40, height: 1)
                        .padding(.top, 4)

                    Text("Agendamentos inteligentes")
                        .font(BarberDesignSystem.caption())
                        .tracking(2)
                        .foregroundColor(BarberDesignSystem.textSecondary)
                        .padding(.top, 2)
                }
                .opacity(titleOpacity)
                .offset(y: titleOffset)
            }
        }
        .onAppear { startAnimations() }
    }

    private func startAnimations() {
        withAnimation(.spring(response: 0.7, dampingFraction: 0.6).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.6).delay(0.5)) {
            titleOpacity = 1.0
            titleOffset = 0
        }

        withAnimation(.easeOut(duration: 1.0).delay(0.4)) {
            wavesOffset = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            onFinished()
        }
    }
}

// MARK: - Preview
#Preview {
    SplashScreenView(onFinished: {})
}
