//
//  AddPantryIngredientView.swift
//  FridgeFix
//
//  Created by Codex on 8/9/2026.
//

import SwiftUI

/// Lets the user discover local pantry ingredient options and add one.
struct AddPantryIngredientView: View {

    @StateObject private var viewModel: AddPantryIngredientViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: AddPantryIngredientViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: FridgeFixTheme.sectionSpacing) {
                    searchHeader

                    if let errorMessage = viewModel.errorMessage {
                        AddIngredientMessageView(
                            message: errorMessage,
                            systemImage: "exclamationmark.triangle",
                            tint: .orange
                        )
                    }

                    if let successfulAdditionMessage =
                        viewModel.successfulAdditionMessage {
                        AddIngredientMessageView(
                            message: successfulAdditionMessage,
                            systemImage: "checkmark.circle",
                            tint: FridgeFixTheme.brandAccent
                        )
                    }

                    browseCategoriesSection
                    commonAdditionsSection
                    ingredientCatalogueSection
                }
                .padding(FridgeFixTheme.screenPadding)
            }
            .background(FridgeFixTheme.pageBackground)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(
                item: $viewModel.selectedIngredient
            ) { ingredient in
                AddIngredientConfirmationSheet(
                    ingredient: ingredient,
                    viewModel: viewModel
                )
                .presentationDetents([.medium])
            }
        }
    }

    private var searchHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(FridgeFixTheme.secondaryText)
                    .accessibilityHidden(true)

                TextField("Search ingredients", text: $viewModel.searchText)
                    .font(.headline)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                    .accessibilityLabel("Search ingredients")

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(FridgeFixTheme.secondaryText)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Clear ingredient search")
                }
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 54)
            .background(FridgeFixTheme.cardBackground)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: FridgeFixTheme.compactCornerRadius,
                    style: .continuous
                )
            )

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.bordered)
            .clipShape(Circle())
            .accessibilityLabel("Close add ingredient")
        }
        .accessibilityElement(children: .contain)
    }

    private var browseCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse Categories")
                .fridgeFixSectionTitle()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CategoryCard(
                        title: "All",
                        category: nil,
                        isSelected: viewModel.selectedCategory == nil
                    ) {
                        viewModel.selectCategory(nil)
                    }

                    ForEach(
                        viewModel.availableCategories,
                        id: \.self
                    ) { category in
                        CategoryCard(
                            title: category.addFlowDisplayName,
                            category: category,
                            isSelected: viewModel.selectedCategory == category
                        ) {
                            viewModel.selectCategory(category)
                        }
                    }
                }
                .padding(.trailing, 4)
            }
        }
    }

    private var commonAdditionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Common Additions")
                .fridgeFixSectionTitle()

            if viewModel.commonIngredientOptions.isEmpty {
                Text("No common additions match this search.")
                    .font(.subheadline)
                    .foregroundStyle(FridgeFixTheme.secondaryText)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.commonIngredientOptions) { ingredient in
                            CommonIngredientChip(ingredient: ingredient) {
                                viewModel.beginAdding(ingredient)
                            }
                        }
                    }
                    .padding(.trailing, 4)
                }
            }
        }
    }

    private var ingredientCatalogueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .fridgeFixSectionTitle()

            if viewModel.filteredIngredientOptions.isEmpty {
                ContentUnavailableView {
                    Label("No ingredients found", systemImage: "magnifyingglass")
                } description: {
                    Text("Try another search or return to all categories.")
                }
            } else {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.filteredIngredientOptions) { ingredient in
                        IngredientCatalogueRow(ingredient: ingredient) {
                            viewModel.beginAdding(ingredient)
                        }
                    }
                }
            }
        }
    }
}

private struct CategoryCard: View {

    let title: String
    let category: IngredientSubstitutionCategory?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                IngredientArtworkView(
                    kind: .category(category),
                    size: CGSize(width: 148, height: 94),
                    cornerRadius: FridgeFixTheme.compactCornerRadius
                )

                LinearGradient(
                    colors: [
                        .black.opacity(0.05),
                        .black.opacity(0.62)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Text(title)
                    .font(.subheadline)
                    .fontDesign(.rounded)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .padding(10)
            }
            .frame(width: 148, height: 94)
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
                    isSelected ? FridgeFixTheme.brandAccent : .clear,
                    lineWidth: 3
                )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) category")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct CommonIngredientChip: View {

    let ingredient: PantryIngredientOption
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                IngredientArtworkView(
                    kind: .ingredient(
                        name: ingredient.name,
                        category: ingredient.category
                    ),
                    size: CGSize(width: 34, height: 34),
                    isCircular: true
                )

                Text(ingredient.name)
                    .font(.subheadline)
                    .fontDesign(.rounded)
                    .fontWeight(.semibold)
                    .foregroundStyle(FridgeFixTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .padding(.leading, 6)
            .padding(.trailing, 12)
            .frame(minHeight: 46)
            .background(FridgeFixTheme.cardBackground)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add \(ingredient.name)")
    }
}

private struct IngredientCatalogueRow: View {

    let ingredient: PantryIngredientOption
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            IngredientArtworkView(
                kind: .ingredient(
                    name: ingredient.name,
                    category: ingredient.category
                ),
                size: CGSize(width: 54, height: 54),
                cornerRadius: 10
            )
            .accessibilityLabel("\(ingredient.name) photo")

            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .fridgeFixCardTitle()
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(ingredient.category.addFlowDisplayName)
                    .font(.caption)
                    .foregroundStyle(FridgeFixTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button(action: action) {
                Label("Add", systemImage: "plus")
                    .font(.subheadline)
                    .fontDesign(.rounded)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .accessibilityLabel("Add \(ingredient.name)")
        }
        .padding(12)
        .background(FridgeFixTheme.cardBackground)
        .clipShape(
            RoundedRectangle(
                cornerRadius: FridgeFixTheme.compactCornerRadius,
                style: .continuous
            )
        )
    }
}

private struct AddIngredientMessageView: View {

    let message: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label {
            Text(message)
                .font(.subheadline)
                .foregroundStyle(FridgeFixTheme.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
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
    }
}

private struct AddIngredientConfirmationSheet: View {

    let ingredient: PantryIngredientOption
    @ObservedObject var viewModel: AddPantryIngredientViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Ingredient") {
                    HStack(spacing: 12) {
                        IngredientArtworkView(
                            kind: .ingredient(
                                name: ingredient.name,
                                category: ingredient.category
                            ),
                            size: CGSize(width: 44, height: 44),
                            isCircular: true
                        )
                        .accessibilityLabel("\(ingredient.name) photo")

                        VStack(alignment: .leading, spacing: 4) {
                            Text(ingredient.name)
                                .fridgeFixCardTitle()
                            Text(ingredient.category.addFlowDisplayName)
                                .font(.caption)
                                .foregroundStyle(FridgeFixTheme.secondaryText)
                        }
                    }
                }

                Section("Expiry") {
                    Toggle(
                        "Has expiry date",
                        isOn: $viewModel.hasExpiryDate
                    )

                    if viewModel.hasExpiryDate {
                        DatePicker(
                            "Expiry Date",
                            selection: $viewModel.expiryDate,
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationTitle("Add Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(FridgeFixTheme.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelSelectedIngredient()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        viewModel.addSelectedIngredient()
                        if viewModel.selectedIngredient == nil {
                            dismiss()
                        }
                    } label: {
                        if viewModel.isAddingIngredient {
                            ProgressView()
                        } else {
                            Text("Add")
                        }
                    }
                    .disabled(viewModel.isAddingIngredient)
                    .accessibilityLabel("Confirm add \(ingredient.name)")
                }
            }
        }
    }
}

#Preview {
    AddPantryIngredientView(
        viewModel: AddPantryIngredientViewModel()
    )
}
