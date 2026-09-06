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
                            isUrgent: true
                        )
                    }
                }
            }

            Section("All Ingredients") {
                ForEach(viewModel.ingredients) { ingredient in
                    PantryIngredientRow(
                        ingredient: ingredient,
                        isUrgent: ingredient.isExpiringSoon
                    )
                }
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
            }

            Spacer()

            if isUrgent {
                Text("Use soon")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }
}

#Preview {
    PantryView()
}
