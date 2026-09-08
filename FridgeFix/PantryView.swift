//
//  PantryView.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import SwiftUI

/// Displays the ingredients currently available in the user's pantry.
struct PantryView: View {

    @ObservedObject var viewModel: PantryViewModel
    @ObservedObject var recommendationsViewModel: RecommendationsViewModel

    init(
        viewModel: PantryViewModel,
        recommendationsViewModel: RecommendationsViewModel
    ) {
        self.viewModel = viewModel
        self.recommendationsViewModel = recommendationsViewModel
    }

    var body: some View {
        NavigationStack {
            pantryContent
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(.hidden, for: .navigationBar)
                .task {
                    viewModel.loadPantry()
                }
                .fullScreenCover(isPresented: $viewModel.isShowingAddIngredient) {
                    AddPantryIngredientView(
                        viewModel: viewModel.makeAddPantryIngredientViewModel()
                    )
                }
                .sheet(
                    item: $viewModel.ingredientBeingEditedForExpiry
                ) { ingredient in
                    EditExpiryDateView(
                        ingredient: ingredient,
                        viewModel: viewModel
                    )
                }
                .background(FridgeFixTheme.pageBackground)
        }
    }

    private var pantryContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PantryHeader(
                    refresh: {
                        viewModel.loadPantry()
                    },
                    addIngredient: {
                        viewModel.isShowingAddIngredient = true
                    }
                )

                cookAction

                if let errorMessage = viewModel.errorMessage {
                    PantryDashboardMessage(
                        message: errorMessage,
                        systemImage: "exclamationmark.triangle",
                        tint: .orange,
                        actionTitle: "Refresh pantry",
                        actionSystemImage: "arrow.clockwise",
                        action: {
                            viewModel.loadPantry()
                        }
                    )
                }

                if viewModel.ingredients.isEmpty {
                    emptyPantryCard
                } else {
                    PantryDashboard(
                        featuredIngredient: viewModel.featuredIngredient,
                        categories: viewModel.availableCategoryFilters,
                        selectedCategory: viewModel.selectedCategory,
                        selectCategory: { category in
                            viewModel.selectedCategory = category
                        },
                        editExpiryDate: { ingredient in
                            viewModel.beginEditingExpiryDate(for: ingredient)
                        }
                    )

                    PantrySearchField(searchText: $viewModel.searchText)

                    ingredientCardsSection
                }
            }
            .padding(.horizontal, FridgeFixTheme.screenPadding)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .background(FridgeFixTheme.pageBackground)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 18)
        }
    }

    private var cookAction: some View {
        NavigationLink {
            CookingContextView(
                recommendationsViewModel: recommendationsViewModel
            )
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .accessibilityHidden(true)

                Text("What can I cook?")
                    .fridgeFixPrimaryActionTitle()
                    .lineLimit(1)

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: FridgeFixTheme.compactActionHeight)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.hasPantryIngredients)
        .accessibilityHint(
            viewModel.hasPantryIngredients
                ? "Starts meal recommendations using your pantry."
                : "Add an ingredient before starting meal recommendations."
        )
    }

    private var emptyPantryCard: some View {
        PantryDashboardMessage(
            message: "Add a few pantry ingredients before FridgeFix can recommend realistic meals.",
            systemImage: "refrigerator",
            tint: FridgeFixTheme.brandAccent,
            actionTitle: "Add ingredient",
            actionSystemImage: "plus",
            action: {
                viewModel.isShowingAddIngredient = true
            }
        )
    }

    private var ingredientCardsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Pantry Ingredients")
                    .fridgeFixSectionTitle()

                Spacer(minLength: 8)

                if viewModel.hasActiveFilters {
                    Button {
                        viewModel.clearFilters()
                    } label: {
                        Label("Clear", systemImage: "xmark.circle")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .accessibilityLabel("Clear pantry filters")
                }
            }

            if viewModel.isShowingFilteredEmptyState {
                PantryDashboardMessage(
                    message: "No pantry ingredients match these filters.",
                    systemImage: "magnifyingglass",
                    tint: FridgeFixTheme.secondaryText,
                    actionTitle: "Clear filters",
                    actionSystemImage: "xmark.circle",
                    action: {
                        viewModel.clearFilters()
                    }
                )
            } else if viewModel.visibleIngredientsExcludingFeatured.isEmpty {
                Text("Featured above. Clear filters or add another ingredient to see more pantry cards.")
                    .font(.subheadline)
                    .foregroundStyle(FridgeFixTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(FridgeFixTheme.cardBackground)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: FridgeFixTheme.compactCornerRadius,
                            style: .continuous
                        )
                    )
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.visibleIngredientsExcludingFeatured) { ingredient in
                        PantryIngredientCard(
                            ingredient: ingredient,
                            editExpiryDate: {
                                viewModel.beginEditingExpiryDate(for: ingredient)
                            },
                            deleteIngredient: {
                                viewModel.removePantryIngredients([ingredient])
                            }
                        )
                    }
                }
            }
        }
    }
}

private struct PantryHeader: View {

    let refresh: () -> Void
    let addIngredient: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("My Pantry")
                    .fridgeFixScreenTitle()

                Text("Make the most of what you already have.")
                    .font(.subheadline)
                    .foregroundStyle(FridgeFixTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            HStack(spacing: 8) {
                Button(action: refresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.headline)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.bordered)
                .clipShape(Circle())
                .accessibilityLabel("Refresh pantry")

                Button(action: addIngredient) {
                    Image(systemName: "plus")
                        .font(.headline)
                        .frame(width: 40, height: 40)
                }
                .buttonStyle(.borderedProminent)
                .clipShape(Circle())
                .accessibilityLabel("Add ingredient")
            }
        }
    }
}

private struct PantryDashboard: View {

    let featuredIngredient: PantryIngredient?
    let categories: [IngredientSubstitutionCategory]
    let selectedCategory: IngredientSubstitutionCategory?
    let selectCategory: (IngredientSubstitutionCategory?) -> Void
    let editExpiryDate: (PantryIngredient) -> Void

    var body: some View {
        GeometryReader { proxy in
            let spacing: CGFloat = 12
            let columnWidth = max((proxy.size.width - spacing) / 2, 0)

            HStack(alignment: .top, spacing: spacing) {
                if let featuredIngredient {
                    FeaturedIngredientCard(
                        ingredient: featuredIngredient,
                        width: columnWidth,
                        editExpiryDate: {
                            editExpiryDate(featuredIngredient)
                        }
                    )
                    .frame(width: columnWidth)
                }

                CategoryGrid(
                    categories: categories,
                    selectedCategory: selectedCategory,
                    width: columnWidth,
                    selectCategory: selectCategory
                )
                .frame(width: columnWidth)
            }
        }
        .frame(height: 220)
    }
}

private struct FeaturedIngredientCard: View {

    let ingredient: PantryIngredient
    let width: CGFloat
    let editExpiryDate: () -> Void

    var body: some View {
        Button(action: editExpiryDate) {
            ZStack(alignment: .bottomLeading) {
                IngredientArtworkView(
                    kind: .ingredient(
                        name: ingredient.name,
                        category: ingredient.substitutionCategory
                    ),
                    size: CGSize(width: width, height: 220),
                    cornerRadius: FridgeFixTheme.cardCornerRadius
                )

                LinearGradient(
                    colors: [
                        .black.opacity(0.08),
                        .black.opacity(0.72)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 8) {
                    if ingredient.isExpiringSoon {
                        Text("Use Soon")
                            .font(.caption2)
                            .fontDesign(.rounded)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(.orange)
                            .clipShape(Capsule())
                    }

                    Spacer(minLength: 0)

                    Text(ingredient.name)
                        .font(.headline)
                        .fontDesign(.rounded)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(expiryText)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.88))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)

                VStack {
                    HStack {
                        Spacer()
                        Button(action: editExpiryDate) {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(FridgeFixTheme.primaryText)
                                .frame(width: 34, height: 34)
                                .background(.white.opacity(0.92))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Edit \(ingredient.name) expiry date")
                    }
                    Spacer()
                }
                .padding(10)
            }
            .frame(width: width, height: 220)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: FridgeFixTheme.cardCornerRadius,
                    style: .continuous
                )
            )
            .shadow(color: .black.opacity(0.10), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Featured ingredient, \(ingredient.name), \(expiryText)"
        )
        .accessibilityHint("Opens expiry date editing.")
    }

    private var expiryText: String {
        guard let expiresAt = ingredient.expiresAt else {
            return "Expiry date unknown"
        }

        return "Expires \(expiresAt.formatted(date: .abbreviated, time: .omitted))"
    }
}

private struct CategoryGrid: View {

    let categories: [IngredientSubstitutionCategory]
    let selectedCategory: IngredientSubstitutionCategory?
    let width: CGFloat
    let selectCategory: (IngredientSubstitutionCategory?) -> Void

    private var gridItems: [PantryCategoryGridItem] {
        [PantryCategoryGridItem(category: nil)] +
        categories.map { PantryCategoryGridItem(category: $0) }
    }

    var body: some View {
        let spacing: CGFloat = 8
        let cardWidth = max((width - spacing) / 2, 0)
        let rowCount = CGFloat(max((gridItems.count + 1) / 2, 1))
        let cardHeight = max((220 - (spacing * (rowCount - 1))) / rowCount, 0)

        LazyVGrid(
            columns: [
                GridItem(.fixed(cardWidth), spacing: spacing),
                GridItem(.fixed(cardWidth), spacing: spacing)
            ],
            spacing: spacing
        ) {
            ForEach(gridItems) { item in
                CategoryDashboardCard(
                    title: item.title,
                    category: item.category,
                    isSelected: item.category == selectedCategory,
                    size: CGSize(width: cardWidth, height: cardHeight),
                    action: {
                        selectCategory(item.category)
                    }
                )
            }
        }
    }
}

private struct PantryCategoryGridItem: Identifiable {

    let category: IngredientSubstitutionCategory?

    var id: String {
        category?.rawValue ?? "all"
    }

    var title: String {
        category?.addFlowDisplayName ?? "All"
    }
}

private struct CategoryDashboardCard: View {

    let title: String
    let category: IngredientSubstitutionCategory?
    let isSelected: Bool
    let size: CGSize
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                IngredientArtworkView(
                    kind: .category(category),
                    size: size,
                    cornerRadius: FridgeFixTheme.compactCornerRadius
                )

                LinearGradient(
                    colors: [
                        .black.opacity(0.02),
                        .black.opacity(0.64)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Text(title)
                    .font(.caption)
                    .fontDesign(.rounded)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .padding(8)
            }
            .frame(width: size.width, height: size.height)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: FridgeFixTheme.compactCornerRadius,
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: FridgeFixTheme.compactCornerRadius,
                    style: .continuous
                )
                .stroke(
                    isSelected ? FridgeFixTheme.brandAccent : .white.opacity(0.18),
                    lineWidth: isSelected ? 3 : 1
                )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) pantry category")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Displays a compact pantry search field for existing pantry ingredients.
private struct PantrySearchField: View {

    @Binding var searchText: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(FridgeFixTheme.secondaryText)
                .accessibilityHidden(true)

            TextField("Search your pantry", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .accessibilityLabel("Search your pantry")

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(FridgeFixTheme.secondaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear pantry search")
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 42)
        .background(FridgeFixTheme.cardBackground)
        .clipShape(
            RoundedRectangle(
                cornerRadius: FridgeFixTheme.compactCornerRadius,
                style: .continuous
            )
        )
    }
}

/// Displays one pantry ingredient and its expiry status.
private struct PantryIngredientCard: View {

    let ingredient: PantryIngredient
    let editExpiryDate: () -> Void
    let deleteIngredient: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            IngredientArtworkView(
                kind: .ingredient(
                    name: ingredient.name,
                    category: ingredient.substitutionCategory
                ),
                size: CGSize(width: 58, height: 58),
                cornerRadius: 12
            )
            .accessibilityLabel("\(ingredient.name) photo")

            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(ingredient.name)
                        .fridgeFixCardTitle()
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if ingredient.isExpiringSoon {
                        Image(systemName: "clock.badge.exclamationmark.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .accessibilityLabel("Use soon")
                    }
                }

                Text(ingredient.substitutionCategory.addFlowDisplayName)
                    .font(.caption)
                    .foregroundStyle(FridgeFixTheme.secondaryText)

                Text(expiryText)
                    .font(.caption)
                    .foregroundStyle(
                        ingredient.isExpiringSoon
                            ? .orange
                            : FridgeFixTheme.secondaryText
                    )
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            VStack(spacing: 6) {
                Button(action: editExpiryDate) {
                    Image(systemName: "pencil.circle")
                        .font(.title3)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(expiryActionAccessibilityLabel)
                .accessibilityHint(
                    "Changes the stored expiry date for this pantry ingredient."
                )

                Button(role: .destructive, action: deleteIngredient) {
                    Image(systemName: "trash")
                        .font(.subheadline)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Delete \(ingredient.name)")
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FridgeFixTheme.cardBackground)
        .clipShape(
            RoundedRectangle(
                cornerRadius: FridgeFixTheme.compactCornerRadius,
                style: .continuous
            )
        )
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }

    private var expiryText: String {
        guard let expiresAt = ingredient.expiresAt else {
            return "Expiry date unknown"
        }

        return "Expires \(expiresAt.formatted(date: .abbreviated, time: .omitted))"
    }

    private var expiryActionAccessibilityLabel: String {
        if ingredient.expiresAt == nil {
            return "Add expiry date for \(ingredient.name)"
        }

        return "Edit \(ingredient.name) expiry date"
    }
}

private struct PantryDashboardMessage: View {

    let message: String
    let systemImage: String
    let tint: Color
    let actionTitle: String
    let actionSystemImage: String
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(FridgeFixTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(tint)
            }

            Button(action: action) {
                Label(actionTitle, systemImage: actionSystemImage)
                    .font(.subheadline)
                    .fontDesign(.rounded)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FridgeFixTheme.cardBackground)
        .clipShape(
            RoundedRectangle(
                cornerRadius: FridgeFixTheme.compactCornerRadius,
                style: .continuous
            )
        )
    }
}

/// Updates or clears the expiry date for an existing pantry ingredient.
private struct EditExpiryDateView: View {

    let ingredient: PantryIngredient
    @ObservedObject var viewModel: PantryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Ingredient") {
                    Text(ingredient.name)
                    Text(ingredient.substitutionCategory.displayName)
                        .foregroundStyle(FridgeFixTheme.secondaryText)
                }

                Section("Expiry") {
                    Toggle(
                        "Has expiry date",
                        isOn: $viewModel.editedIngredientHasExpiryDate
                    )

                    if viewModel.editedIngredientHasExpiryDate {
                        DatePicker(
                            "Expiry Date",
                            selection: $viewModel.editedIngredientExpiryDate,
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationTitle("Edit Expiry")
            .scrollContentBackground(.hidden)
            .background(FridgeFixTheme.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelEditingExpiryDate()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveEditedExpiryDate()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PantryView(
        viewModel: PantryViewModel(),
        recommendationsViewModel: RecommendationsViewModel()
    )
}
