import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss

    private let appStoreURL = URL(string: "https://apps.apple.com/us/app/simply-dice-roll-anywhere/id6759136034")!

    private var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        ZStack {
            // Dark background with radial gradient
            Color(white: 0.02).ignoresSafeArea()
            RadialGradient(
                gradient: Gradient(colors: [Color(white: 0.11), Color.black]),
                center: .center,
                startRadius: 0,
                endRadius: 400
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // MARK: Header
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(alignment: .center) {
                            HStack(spacing: 12) {
                                // Mini die icon
                                MiniDieView()
                                Text("Simply Dice")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.white, Color(white: 0.73)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                            Spacer()
                            // Done button — pill shape
                            Button("Done") { dismiss() }
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color(white: 0.07))
                                .overlay(
                                    Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
                                )
                                .clipShape(Capsule())
                        }
                        .padding(.bottom, 8)

                        Text("Roll preferences")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(white: 0.4))
                            .padding(.leading, 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 32)

                    // MARK: Controls card
                    VStack(spacing: 0) {
                        SettingsRow(
                            icon: "speaker.wave.2.fill",
                            title: "Sound",
                            subtitle: "Play roll effects",
                            isOn: $settings.sound
                        )
                        RowDivider()
                        SettingsRow(
                            icon: "iphone.radiowaves.left.and.right",
                            title: "Haptics",
                            subtitle: "Vibrate on impact",
                            isOn: $settings.haptics
                        )
                        RowDivider()
                        SettingsRow(
                            icon: "arrow.triangle.2.circlepath",
                            title: "Shake",
                            subtitle: "Shake device to roll",
                            isOn: $settings.shake
                        )
                    }
                    .background(Color(white: 0.063))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // MARK: Share card
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Share App")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(white: 0.93))
                            Text("Send to a friend")
                                .font(.system(size: 12))
                                .foregroundColor(Color(white: 0.4))
                        }
                        Spacer()
                        ShareLink(item: appStoreURL) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    .padding(20)
                    .background(Color(white: 0.063))
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)

                    // MARK: About
                    VStack(spacing: 4) {
                        Text("Simply Dice")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text("Version \(versionString)")
                            .font(.system(size: 12))
                            .foregroundColor(Color(white: 0.33))
                        Text("Made with ❤️ in Gainesville, FL")
                            .font(.system(size: 10))
                            .foregroundColor(Color(white: 0.27))
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                    .opacity(0.8)
                }
            }
        }
    }
}

// MARK: - Supporting views

private struct MiniDieView: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(.white)
                .frame(width: 28, height: 28)
                .shadow(color: .white.opacity(0.1), radius: 4, x: 0, y: 2)
            HStack {
                Circle().fill(Color.black).frame(width: 6, height: 6)
                    .frame(maxHeight: .infinity, alignment: .top)
                Circle().fill(Color.black).frame(width: 6, height: 6)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .padding(4)
            .frame(width: 28, height: 28)
        }
    }
}

private struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(white: 0.87))
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(white: 0.93))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color(white: 0.4))
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(minHeight: 64)
    }
}

private struct RowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
            .padding(.horizontal, 20)
    }
}

#Preview {
    SettingsView()
        .environmentObject(SettingsStore())
}
