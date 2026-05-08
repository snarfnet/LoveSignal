import SwiftUI

struct LoveBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(colors: [AppColors.backgroundTop, AppColors.backgroundBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle()
                .fill(AppColors.accentRose.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 70)
                .offset(x: -150, y: -260)
            Circle()
                .fill(AppColors.accentLavender.opacity(0.13))
                .frame(width: 340, height: 340)
                .blur(radius: 80)
                .offset(x: 160, y: 260)
        }
        .ignoresSafeArea()
    }
}

struct RoseCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(18)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.85), lineWidth: 1)
            )
            .shadow(color: AppColors.shadowColor, radius: 18, x: 0, y: 10)
    }
}

struct LoveHeroCard: View {
    let imageName: String
    let title: String
    let subtitle: String
    var height: CGFloat = 240

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(height: height)
                .clipped()

            LinearGradient(colors: [.clear, .black.opacity(0.72)], startPoint: .center, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: AppColors.accentLavender.opacity(0.22), radius: 20, x: 0, y: 12)
    }
}

struct CategoryBadge: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(AppFonts.caption(11))
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color)
            .clipShape(Capsule())
    }
}

struct HeartButton: View {
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(isFavorite ? AppColors.accentRose : AppColors.textWarm)
                .frame(width: 38, height: 38)
                .background(Color.white.opacity(0.7))
                .clipShape(Circle())
                .scaleEffect(isFavorite ? 1.08 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFavorite)
        }
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppColors.accentRose)
            Text(title)
                .font(AppFonts.headline(18))
                .foregroundColor(AppColors.textDark)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 2)
    }
}

struct GradientTitle: View {
    let text: String
    let size: CGFloat

    var body: some View {
        Text(text)
            .font(AppFonts.title(size))
            .foregroundStyle(
                LinearGradient(colors: [AppColors.accentRose, AppColors.accentLavender], startPoint: .leading, endPoint: .trailing)
            )
    }
}

struct EmptyStateView: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 42, weight: .bold))
                .foregroundColor(AppColors.accentRose.opacity(0.5))
            Text(message)
                .font(AppFonts.body(15))
                .foregroundColor(AppColors.textWarm)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(34)
    }
}

struct ScoreBar: View {
    let label: String
    let value: Int
    let maxValue: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                    .font(AppFonts.caption(13))
                    .foregroundColor(AppColors.textWarm)
                Spacer()
                Text("\(value)")
                    .font(AppFonts.caption(13))
                    .foregroundColor(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(color.opacity(0.14))
                        .frame(height: 9)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(color)
                        .frame(width: maxValue > 0 ? geo.size.width * CGFloat(value) / CGFloat(maxValue) : 0, height: 9)
                }
            }
            .frame(height: 9)
        }
    }
}

struct PulsingHeart: View {
    @State private var pulsing = false

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 56, weight: .bold))
            .foregroundStyle(LinearGradient(colors: [AppColors.accentRose, AppColors.accentCoral], startPoint: .topLeading, endPoint: .bottomTrailing))
            .scaleEffect(pulsing ? 1.08 : 1.0)
            .shadow(color: AppColors.accentRose.opacity(0.35), radius: pulsing ? 16 : 8)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.25).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }
    }
}
