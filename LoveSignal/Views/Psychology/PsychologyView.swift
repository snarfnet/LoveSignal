import SwiftUI

struct PsychologyView: View {
    @EnvironmentObject var vm: PsychologyViewModel
    @State private var selectedTechnique: PsychologyTechnique?

    var body: some View {
        NavigationStack {
            ZStack {
                LoveBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        LoveHeroCard(
                            imageName: "love-psychology",
                            title: "恋愛心理を見える化",
                            subtitle: "第一印象、距離感、会話の流れを実践しやすく整理"
                        )
                        .padding(.horizontal, 20)

                        searchBar
                        categoryFilter
                        techniquesSection
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("心理テクニック")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedTechnique) { technique in
                TechniqueDetailView(technique: technique)
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textWarm)
            TextField("テクニックを検索", text: $vm.searchText)
                .font(AppFonts.body(15))
                .foregroundColor(AppColors.textDark)
        }
        .padding(14)
        .background(Color.white.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 20)
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                categoryChip(title: "すべて", icon: "sparkles", isSelected: vm.selectedCategory == nil) {
                    vm.selectedCategory = nil
                }
                ForEach(PsychologyCategory.allCases, id: \.self) { category in
                    categoryChip(title: category.rawValue, icon: category.icon, isSelected: vm.selectedCategory == category) {
                        vm.selectedCategory = vm.selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func categoryChip(title: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(AppFonts.caption(13))
            .foregroundColor(isSelected ? .white : AppColors.textWarm)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isSelected ? AppColors.accentRose : Color.white.opacity(0.75))
            .clipShape(Capsule())
        }
    }

    private var techniquesSection: some View {
        LazyVStack(spacing: 14) {
            if vm.filteredTechniques.isEmpty {
                EmptyStateView(icon: "magnifyingglass", message: "条件に合うテクニックが見つかりません。")
            } else {
                ForEach(vm.filteredTechniques) { technique in
                    techniqueCard(technique)
                        .padding(.horizontal, 20)
                        .onTapGesture { selectedTechnique = technique }
                }
            }
        }
    }

    private func techniqueCard(_ technique: PsychologyTechnique) -> some View {
        RoseCard {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: technique.category.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.accentLavender)
                    .frame(width: 46, height: 46)
                    .background(AppColors.accentLavender.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(technique.name)
                            .font(AppFonts.headline(16))
                            .foregroundColor(AppColors.textDark)
                        Spacer()
                    }
                    Text(technique.summary)
                        .font(AppFonts.body(13))
                        .foregroundColor(AppColors.textWarm)
                        .lineLimit(3)
                    CategoryBadge(text: technique.category.rawValue, color: AppColors.accentLavender)
                }
            }
        }
    }
}
