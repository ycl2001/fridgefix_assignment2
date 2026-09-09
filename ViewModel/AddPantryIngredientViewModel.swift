//
//  AddPantryIngredientViewModel.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 8/9/2026.
//

import Foundation
import Combine

/// Manages ingredient discovery and pantry additions for the add-pantry flow.
@MainActor
final class AddPantryIngredientViewModel: ObservableObject {

    @Published var searchText = ""
    @Published var selectedCategory: IngredientSubstitutionCategory?
    @Published var selectedIngredient: PantryIngredientOption?
    @Published var hasExpiryDate = false
    @Published var expiryDate = Date()
    @Published private(set) var isAddingIngredient = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var successfulAdditionMessage: String?

    private let ingredientCatalogue: [PantryIngredientOption]
    private let pantryRepository: any PantryRepository
    private let onPantryChanged: () -> Void

    init(
        ingredientCatalogue: [PantryIngredientOption] =
            SampleIngredientCatalogue.ingredients,
        pantryRepository: any PantryRepository = LocalPantryRepository.shared,
        onPantryChanged: @escaping () -> Void = {}
    ) {
        self.ingredientCatalogue = ingredientCatalogue
        self.pantryRepository = pantryRepository
        self.onPantryChanged = onPantryChanged
    }

    var availableCategories: [IngredientSubstitutionCategory] {
        let representedCategories = Set(ingredientCatalogue.map(\.category))

        return IngredientSubstitutionCategory.allCases.filter {
            representedCategories.contains($0)
        }
    }

    var filteredIngredientOptions: [PantryIngredientOption] {
        ingredientCatalogue.filter { option in
            matchesSearch(option) && matchesSelectedCategory(option)
        }
    }

    var commonIngredientOptions: [PantryIngredientOption] {
        filteredIngredientOptions.filter(\.isCommonlyAdded)
    }

    func selectCategory(_ category: IngredientSubstitutionCategory?) {
        selectedCategory = category
    }

    func clearSearch() {
        searchText = ""
    }

    func beginAdding(_ option: PantryIngredientOption) {
        selectedIngredient = option
        hasExpiryDate = false
        expiryDate = Date()
        errorMessage = nil
        successfulAdditionMessage = nil
    }

    func cancelSelectedIngredient() {
        selectedIngredient = nil
        hasExpiryDate = false
        expiryDate = Date()
    }

    func addSelectedIngredient() {
        guard let selectedIngredient else {
            return
        }

        isAddingIngredient = true
        errorMessage = nil
        successfulAdditionMessage = nil

        let ingredient = PantryIngredient(
            id: IngredientID(rawValue: selectedIngredient.id),
            name: selectedIngredient.name,
            substitutionCategory: selectedIngredient.category,
            expiresAt: hasExpiryDate ? expiryDate : nil
        )

        do {
            try pantryRepository.addPantryIngredient(ingredient)
            isAddingIngredient = false
            successfulAdditionMessage = "\(selectedIngredient.name) was added to your pantry."
            cancelSelectedIngredient()
            onPantryChanged()
        } catch {
            isAddingIngredient = false
            errorMessage = recoveryMessage(for: error)
        }
    }

    private func matchesSearch(_ option: PantryIngredientOption) -> Bool {
        let trimmedSearchText = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard !trimmedSearchText.isEmpty else {
            return true
        }

        return option.name.localizedCaseInsensitiveContains(trimmedSearchText) ||
        option.category.addFlowDisplayName.localizedCaseInsensitiveContains(
            trimmedSearchText
        )
    }

    private func matchesSelectedCategory(
        _ option: PantryIngredientOption
    ) -> Bool {
        guard let selectedCategory else {
            return true
        }

        return option.category == selectedCategory
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

extension IngredientSubstitutionCategory {

    var addFlowDisplayName: String {
        switch self {
        case .leafyGreen:
            return "Leafy Greens"
        case .aromatic:
            return "Aromatics"
        case .protein:
            return "Protein"
        case .grain:
            return "Grains"
        case .cookingOil:
            return "Cooking Essentials"
        }
    }
}
