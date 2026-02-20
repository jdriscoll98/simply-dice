import SwiftUI
import UIKit

struct ContentView: View {
    @EnvironmentObject var settings: SettingsStore

    @State private var isRolling = false
    @State private var showSettings = false

    private let soundManager = SoundManager.shared
    @StateObject private var shakeDetector = ShakeDetector()
    @StateObject private var diceCoordinator = DiceSceneCoordinator()

    var body: some View {
        ZStack {
            // Background — black + radial vignette, centered at 50% 40%
            Color.black.ignoresSafeArea()
            RadialGradient(
                gradient: Gradient(colors: [Color(white: 0.03), Color.black]),
                center: UnitPoint(x: 0.5, y: 0.4),
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()

            // Dice scene — fills entire screen, tap gesture on ZStack handles roll
            DiceView(coordinator: diceCoordinator)
                .ignoresSafeArea()

            // Brand label — top-left
            VStack {
                HStack {
                    Text("Simply Dice")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .opacity(0.22)
                        .padding(.leading, 24)
                    Spacer()

                    // Settings button — top-right frosted glass circle
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.9))
                            .frame(width: 44, height: 44)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                    }
                    .padding(.trailing, 16)
                }
                .padding(.top, 16)

                Spacer()

                // Instructions — bottom
                Text(settings.shake ? "Tap or shake to roll" : "Tap anywhere to roll")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .opacity(isRolling ? 0.3 : 0.55)
                    .animation(.easeInOut(duration: 0.3), value: isRolling)
                    .padding(.bottom, 50)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            handleRoll()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(settings)
        }
        .onAppear {
            diceCoordinator.onRollComplete = {
                DispatchQueue.main.async {
                    isRolling = false
                    if settings.haptics {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                    soundManager.fadeOut()
                }
            }
            if settings.shake {
                startShake()
            }
        }
        .onChange(of: settings.shake) { _, enabled in
            if enabled { startShake() } else { shakeDetector.stop() }
        }
    }

    private func handleRoll() {
        guard !isRolling else { return }
        guard diceCoordinator.roll() else { return }
        isRolling = true
        if settings.sound { soundManager.play() }
        if settings.haptics {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    private func startShake() {
        shakeDetector.onShake = { handleRoll() }
        shakeDetector.start()
    }
}

#Preview {
    ContentView()
        .environmentObject(SettingsStore())
}
