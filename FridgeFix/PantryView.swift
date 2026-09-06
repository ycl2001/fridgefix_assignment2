//
//  PantryView.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import SwiftUI

/// Displays the ingredients currently available in the user's pantry.
struct PantryView: View {

    @StateObject private var viewModel = PantryViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.hasPantryIngredients {
                    pantryContent
                } else {
                    emptyPantryContent
                }
            }
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
        }
    }

    private var pantryContent: some View {
        List {
            Section {
                NavigationLink {
                    CookingContextView()
                } label: {
                    Label(
                        "What can I cook?",
                        systemImage: "sparkles"
                    )
                    .font(.headline)
                }
            }

            if !viewModel.ingredientsExpiringSoon.isEmpty {
                Section("Use Soon") {
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
                }
            }

            Section("All Ingredients") {
                ForEach(viewModel.ingredients) { ingredient in
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
                .onDelete(perform: viewModel.removePantryIngredients)
            }
        }
    }

    private var emptyPantryContent: some View {
        ContentUnavailableView(
            "Your Pantry Is Empty",
            systemImage: "refrigerator",
            description: Text(
                "Add ingredients to discover meals you can realistically cook."
            )
        )
    }
}

/// Displays one pantry ingredient and its expiry status.
private struct PantryIngredientRow: View {

    let ingredient: PantryIngredient
    let isUrgent: Bool
    let editExpiryDate: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "leaf")
                .foregroundStyle(isUrgent ? .orange : .green)

            VStack(alignment: .leading) {
                Text(ingredient.name)
                    .font(.headline)

                Text(ingredient.substitutionCategory.rawValue.capitalized)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let expiresAt = ingredient.expiresAt {
                    Text("Expires \(expiresAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                if isUrgent {
                    Text("Use soon")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Button {
                    editExpiryDate()
                } label: {
                    Image(systemName: "calendar")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Edit expiry date for \(ingredient.name)")
            }
        }
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
                            Text(category.rawValue.capitalized)
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
                    Text(ingredient.substitutionCategory.rawValue.capitalized)
                        .foregroundStyle(.secondary)
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
    PantryView()
}
