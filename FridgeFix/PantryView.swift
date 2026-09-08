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
            .navigationTitle("My Pantry")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.resetAddIngredientForm()
                        viewModel.isShowingAddIngredient = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add ingredient")
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.loadPantry()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Refresh pantry")
                }
            }
            .task {
                viewModel.loadPantry()
            }
            .sheet(isPresented: $viewModel.isShowingAddIngredient) {
                AddIngredientView(viewModel: viewModel)
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
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text("See what you can realistically cook with the ingredients you already have.")
                        .font(.subheadline)
                        .foregroundStyle(FridgeFixTheme.secondaryText)

                    NavigationLink {
                        CookingContextView(
                            recommendationsViewModel:
                                recommendationsViewModel
                        )
                    } label: {
                        Label(
                            "What can I cook?",
                            systemImage: "sparkles"
                        )
                        .fridgeFixPrimaryActionTitle()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.hasPantryIngredients)

                    if !viewModel.hasPantryIngredients {
                        Label(
                            "Add at least one ingredient to start finding realistic meals.",
                            systemImage: "info.circle"
                        )
                        .font(.caption)
                        .foregroundStyle(FridgeFixTheme.secondaryText)
                    }
                }
                .padding(.vertical, 6)
                .listRowBackground(FridgeFixTheme.cardBackground)
            }

            if let errorMessage = viewModel.errorMessage {
                Section("Pantry Help") {
                    Label {
                        Text(errorMessage)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }

                    Button {
                        viewModel.loadPantry()
                    } label: {
                        Label("Refresh pantry", systemImage: "arrow.clockwise")
                    }
                }
                .listRowBackground(FridgeFixTheme.cardBackground)
            }

            if viewModel.ingredientsExpiringSoon.isEmpty {
                Section {
                    Label(
                        "No ingredients need urgent attention today.",
                        systemImage: "checkmark.circle"
                    )
                    .foregroundStyle(FridgeFixTheme.secondaryText)
                }
                .listRowBackground(FridgeFixTheme.cardBackground)
            } else {
                Section {
                    ForEach(viewModel.ingredientsExpiringSoon) { ingredient in
                        PantryIngredientRow(
                            ingredient: ingredient,
                            isUrgent: true,
                            editExpiryDate: {
                                viewModel.beginEditingExpiryDate(
                                    for: ingredient
                                )
                            }
                        )
                    }
                } header: {
                    Label("Use Soon", systemImage: "clock.badge.exclamationmark")
                } footer: {
                    Text("These ingredients expire today or within the next two days.")
                }
                .listRowBackground(FridgeFixTheme.cardBackground)
            }

            if !otherIngredients.isEmpty || viewModel.ingredients.isEmpty {
                Section("Other Ingredients") {
                if viewModel.ingredients.isEmpty {
                    ContentUnavailableView(
                        "Your Pantry Is Empty",
                        systemImage: "refrigerator",
                        description: Text(
                            "Add ingredients to discover meals that fit your real pantry."
                        )
                    )
                } else {
                    ForEach(otherIngredients) { ingredient in
                        PantryIngredientRow(
                            ingredient: ingredient,
                            isUrgent: ingredient.isExpiringSoon,
                            editExpiryDate: {
                                viewModel.beginEditingExpiryDate(
                                    for: ingredient
                                )
                            }
                        )
                    }
                    .onDelete { offsets in
                        viewModel.removePantryIngredients(
                            offsets.map {
                                otherIngredients[$0]
                            }
                        )
                    }
                }
                }
                .listRowBackground(FridgeFixTheme.cardBackground)
            }
        }
        .scrollContentBackground(.hidden)
        .background(FridgeFixTheme.pageBackground)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 16)
        }
    }

    private var otherIngredients: [PantryIngredient] {
        viewModel.ingredients.filter {
            !$0.isExpiringSoon
        }
    }
}

/// Displays one pantry ingredient and its expiry status.
private struct PantryIngredientRow: View {

    let ingredient: PantryIngredient
    let isUrgent: Bool
    let editExpiryDate: () -> Void

    var body: some View {
        HStack {
            Image(
                systemName: isUrgent
                    ? "exclamationmark.triangle.fill"
                    : "leaf.fill"
            )
                .foregroundStyle(isUrgent ? .orange : .green)
                .accessibilityHidden(true)

            VStack(alignment: .leading) {
                Text(ingredient.name)
                    .fridgeFixCardTitle()

                Text(ingredient.substitutionCategory.displayName)
                    .font(.caption)
                    .foregroundStyle(FridgeFixTheme.secondaryText)

                if let expiresAt = ingredient.expiresAt {
                    Text("Expires \(expiresAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(FridgeFixTheme.secondaryText)
                }
            }

            Spacer()

            Button {
                editExpiryDate()
            } label: {
                Image(systemName: "pencil.circle")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(expiryActionAccessibilityLabel)
            .accessibilityHint("Changes the stored expiry date for this pantry ingredient.")
        }
    }

    private var expiryActionAccessibilityLabel: String {
        if ingredient.expiresAt == nil {
            return "Add expiry date for \(ingredient.name)"
        }

        return "Edit \(ingredient.name) expiry date"
    }
}

/// Collects a new pantry ingredient from the user.
private struct AddIngredientView: View {

    @ObservedObject var viewModel: PantryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Ingredient") {
                    TextField(
                        "Name",
                        text: $viewModel.newIngredientName
                    )

                    Picker(
                        "Substitution Category",
                        selection: $viewModel.newIngredientCategory
                    ) {
                        ForEach(
                            IngredientSubstitutionCategory.allCases,
                            id: \.self
                        ) { category in
                            Text(category.displayName)
                                .tag(category)
                        }
                    }
                }

                Section("Expiry") {
                    Toggle(
                        "Has expiry date",
                        isOn: $viewModel.newIngredientHasExpiryDate
                    )

                    if viewModel.newIngredientHasExpiryDate {
                        DatePicker(
                            "Expiry Date",
                            selection: $viewModel.newIngredientExpiryDate,
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationTitle("Add Ingredient")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.resetAddIngredientForm()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addPantryIngredient()
                    }
                }
            }
        }
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
