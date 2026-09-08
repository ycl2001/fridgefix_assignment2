//
//  PantryViewModel.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation
import Combine

/// Provides pantry data and pantry-related display state to the Pantry View.
@MainActor
final class PantryViewModel: ObservableObject {

    @Published private(set) var ingredients: [PantryIngredient] = []
    @Published private(set) var errorMessage: String?
    @Published var isShowingAddIngredient = false
    @Published var newIngredientName = ""
    @Published var newIngredientCategory: IngredientSubstitutionCategory = .protein
    @Published var newIngredientHasExpiryDate = false
    @Published var newIngredientExpiryDate = Date()
    @Published var ingredientBeingEditedForExpiry: PantryIngredient?
    @Published var editedIngredientHasExpiryDate = false
    @Published var editedIngredientExpiryDate = Date()
    @Published var searchText = ""
    @Published var selectedCategory: IngredientSubstitutionCategory?

    private let pantryRepository: any PantryRepository

    init(
        pantryRepository: any PantryRepository = LocalPantryRepository.shared
    ) {
        self.pantryRepository = pantryRepository
    }

    /// Loads the ingredients currently available in the pantry.
    func loadPantry() {
        do {
            ingredients = try pantryRepository.fetchPantryIngredients()
            errorMessage = nil
        } catch PantryRepositoryError.pantryInformationUnavailable {
            errorMessage = """
            Your pantry information is unavailable.
            Try adding an ingredient to begin.
            """
        } catch {
            errorMessage = """
            FridgeFix could not load your pantry.
            Please try again.
            """
        }
    }

    /// Returns ingredients that expire today or within the next two days.
    var ingredientsExpiringSoon: [PantryIngredient] {
        ingredients.filter { $0.isExpiringSoon }
    }

    /// Returns pantry ingredients matching the current search and category filters.
    var visibleIngredients: [PantryIngredient] {
        ingredients.filter { ingredient in
            matchesSearch(ingredient) && matchesSelectedCategory(ingredient)
        }
    }

    /// Returns visible ingredients that expire today or within the next two days.
    var visibleIngredientsExpiringSoon: [PantryIngredient] {
        visibleIngredients.filter { $0.isExpiringSoon }
    }

    /// Returns visible ingredients that are not already represented as urgent.
    var visibleOtherIngredients: [PantryIngredient] {
        visibleIngredients.filter { !$0.isExpiringSoon }
    }

    /// Returns ingredient categories currently represented in the pantry.
    var availableCategoryFilters: [IngredientSubstitutionCategory] {
        let pantryCategories = Set(
            ingredients.map(\.substitutionCategory)
        )

        return IngredientSubstitutionCategory.allCases.filter {
            pantryCategories.contains($0)
        }
    }

    /// Indicates whether search or category filters are currently active.
    var hasActiveFilters: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        selectedCategory != nil
    }

    /// Indicates that filter criteria are hiding all available pantry ingredients.
    var isShowingFilteredEmptyState: Bool {
        !ingredients.isEmpty && visibleIngredients.isEmpty
    }

    /// Indicates whether the user has enough pantry information to continue.
    var hasPantryIngredients: Bool {
        !ingredients.isEmpty
    }

    /// Adds the ingredient described by the current add form.
    func addPantryIngredient() {
        let trimmedName = newIngredientName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedName.isEmpty else {
            errorMessage = """
            Ingredient name is required.
            Add a name before saving.
            """
            return
        }

        let ingredient = PantryIngredient(
            id: IngredientID(
                rawValue: ingredientIDValue(for: trimmedName)
            ),
            name: trimmedName,
            substitutionCategory: newIngredientCategory,
            expiresAt: newIngredientHasExpiryDate
                ? newIngredientExpiryDate
                : nil
        )

        do {
            try pantryRepository.addPantryIngredient(ingredient)
            resetAddIngredientForm()
            isShowingAddIngredient = false
            loadPantry()
        } catch {
            errorMessage = recoveryMessage(for: error)
        }
    }

    /// Removes ingredients at the supplied list offsets.
    func removePantryIngredients(at offsets: IndexSet) {
        do {
            for offset in offsets {
                try pantryRepository.removePantryIngredient(
                    id: ingredients[offset].id
                )
            }

            loadPantry()
        } catch {
            errorMessage = recoveryMessage(for: error)
        }
    }

    /// Removes the supplied ingredients from the pantry.
    func removePantryIngredients(_ ingredientsToRemove: [PantryIngredient]) {
        do {
            for ingredient in ingredientsToRemove {
                try pantryRepository.removePantryIngredient(id: ingredient.id)
            }

            loadPantry()
        } catch {
            errorMessage = recoveryMessage(for: error)
        }
    }

    /// Updates or clears the expiry date for an existing ingredient.
    func updateExpiryDate(
        for ingredient: PantryIngredient,
        expiresAt: Date?
    ) {
        do {
            try pantryRepository.updateExpiryDate(
                for: ingredient.id,
                expiresAt: expiresAt
            )

            loadPantry()
        } catch {
            errorMessage = recoveryMessage(for: error)
        }
    }

    /// Prepares the expiry editor for an existing ingredient.
    func beginEditingExpiryDate(for ingredient: PantryIngredient) {
        ingredientBeingEditedForExpiry = ingredient
        editedIngredientHasExpiryDate = ingredient.expiresAt != nil
        editedIngredientExpiryDate = ingredient.expiresAt ?? Date()
    }

    /// Saves the expiry editor state to the selected ingredient.
    func saveEditedExpiryDate() {
        guard let ingredient = ingredientBeingEditedForExpiry else {
            return
        }

        updateExpiryDate(
            for: ingredient,
            expiresAt: editedIngredientHasExpiryDate
                ? editedIngredientExpiryDate
                : nil
        )

        ingredientBeingEditedForExpiry = nil
    }

    /// Clears any pending expiry edit state.
    func cancelEditingExpiryDate() {
        ingredientBeingEditedForExpiry = nil
        editedIngredientHasExpiryDate = false
        editedIngredientExpiryDate = Date()
    }

    /// Resets the add-ingredient form to its default state.
    func resetAddIngredientForm() {
        newIngredientName = ""
        newIngredientCategory = .protein
        newIngredientHasExpiryDate = false
        newIngredientExpiryDate = Date()
    }

    /// Clears all pantry browsing filters.
    func clearFilters() {
        searchText = ""
        selectedCategory = nil
    }

    private func ingredientIDValue(for name: String) -> String {
        name
            .lowercased()
            .replacingOccurrences(
                of: "[^a-z0-9]+",
                with: "-",
                options: .regularExpression
            )
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }

    private func matchesSearch(_ ingredient: PantryIngredient) -> Bool {
        let trimmedSearchText = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedSearchText.isEmpty else {
            return true
        }

        return ingredient.name.localizedCaseInsensitiveContains(
            trimmedSearchText
        ) ||
        ingredient.substitutionCategory.displayName
            .localizedCaseInsensitiveContains(trimmedSearchText)
    }

    private func matchesSelectedCategory(
        _ ingredient: PantryIngredient
    ) -> Bool {
        guard let selectedCategory else {
            return true
        }

        return ingredient.substitutionCategory == selectedCategory
    }

    private func recoveryMessage(for error: Error) -> String {
        if let pantryError = error as? PantryRepositoryError {
            return [
                pantryError.errorDescription,
                pantryError.recoverySuggestion
            ]
            .compactMap { $0 }
            .joined(separator: "\n")
        }

        return """
        FridgeFix could not update your pantry.
        Please try again.
        """
    }
}
