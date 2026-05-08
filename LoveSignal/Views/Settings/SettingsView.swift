import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                LoveBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        appIdentityCard
                        settingsSection
                        versionFooter
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var appIdentityCard: some View {
        RoseCard {
            VStack(spacing: 16) {
                Image("love-result")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 170)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                GradientTitle(text: "LoveSignal", size: 28)

                Text("恋愛心理を、やさしく使える形に。診断、ヒント、デートプランをひとつにまとめました。")
                    .font(AppFonts.body(15))
                    .foregroundColor(AppColors.textWarm)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }

    private var settingsSection: some View {
        VStack(spacing: 2) {
            settingsRow(icon: "lock.shield.fill", title: "プライバシーポリシー", color: Color(hex: "#8B6FD6")) {
                open("https://tokyonasu.github.io/privacy-policy/lovesignal")
            }
            settingsRow(icon: "doc.text.fill", title: "利用規約", color: AppColors.accentGold) {
                open("https://tokyonasu.github.io/terms/lovesignal")
            }
            settingsRow(icon: "star.fill", title: "App Storeでレビュー", color: AppColors.accentRose) {
                open("https://apps.apple.com/app/id0000000000")
            }
            settingsRow(icon: "envelope.fill", title: "お問い合わせ", color: Color(hex: "#5EA65E")) {
                open("mailto:tokyonasu@gmail.com?subject=LoveSignalお問い合わせ")
            }
        }
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: AppColors.shadowColor, radius: 10, x: 0, y: 5)
    }

    private func settingsRow(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(color)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(title)
                    .font(AppFonts.body(15))
                    .foregroundColor(AppColors.textDark)

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppColors.textWarm.opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
        }
    }

    private var versionFooter: some View {
        VStack(spacing: 6) {
            Text("LoveSignal")
                .font(AppFonts.caption(13))
                .foregroundColor(AppColors.textWarm)
            Text("Version 1.0.0")
                .font(AppFonts.caption(12))
                .foregroundColor(AppColors.textWarm.opacity(0.65))
            Text("(c) 2026 tokyonasu")
                .font(AppFonts.caption(11))
                .foregroundColor(AppColors.textWarm.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func open(_ urlString: String) {
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}
