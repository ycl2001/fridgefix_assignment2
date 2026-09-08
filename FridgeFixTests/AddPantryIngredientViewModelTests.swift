//
//  AddPantryIngredientViewModelTests.swift
//  FridgeFixTests
//
//  Created by Codex on 8/9/2026.
//

import Foundation
import Testing
@testable import FridgeFix

@MainActor
struct AddPantryIngredientViewModelTests {

    @Test
    func searchFindsIngredientByName() {
        let viewModel = makeViewModel()

        viewModel.searchText = "spin"

        #expect(viewModel.filteredIngredientOptions.map(\.name) == ["Spinach"])
    }

    @Test
    func categorySelectionFiltersIngredientOptions() {
        let viewModel = makeViewModel()

        viewModel.selectCategory(.protein)

        #expect(
            viewModel.filteredIngredientOptions.map(\.name) == [
                "Chicken",
                "Tofu"
            ]
        )
    }

    @Test
    func searchAndCategorySelectionWorkTogether() {
        let viewModel = makeViewModel()

        viewModel.selectCategory(.grain)
        viewModel.searchText = "rice"

        #expect(viewModel.filteredIngredientOptions.map(\.name) == ["Rice"])
    }

    @Test
    func clearingSearchRestoresAppropriateOptions() {
        let viewModel = makeViewModel()
        viewModel.selectCategory(.protein)
        viewModel.searchText = "tofu"

        viewModel.clearSearch()

        #expect(
            viewModel.filteredIngredientOptions.map(\.name) == [
                "Chicken",
                "Tofu"
            ]
        )
    }

    @Test
    func successfulAdditionUpdatesPantryState() throws {
        let repository = AddFlowStubPantryRepository()
        var pantryDidChange = false
        let viewModel = makeViewModel(
            repository: repository,
            onPantryChanged: {
                pantryDidChange = true
            }
        )

        viewModel.beginAdding(catalogue[0])
        viewModel.addSelectedIngredient()

        let pantryIngredients = try repository.fetchPantryIngredients()
        #expect(pantryIngredients.map(\.name) == ["Spinach"])
        #expect(pantryDidChange)
        #expect(viewModel.selectedIngredient == nil)
        #expect(viewModel.successfulAdditionMessage == "Spinach was added to your pantry.")
    }

    @Test
    func duplicateIngredientProducesRecoveryMessage() {
        let repository = AddFlowStubPantryRepository(
            ingredients: [
                PantryIngredient(
                    id: IngredientID(rawValue: "spinach"),
                    name: "Spinach",
                    substitutionCategory: .leafyGreen,
                    expiresAt: nil
                )
            ]
        )
        let viewModel = makeViewModel(repository: repository)

        viewModel.beginAdding(catalogue[0])
        viewModel.addSelectedIngredient()

        #expect(
            viewModel.errorMessage == """
            Spinach is already in your pantry.
            Update the existing ingredient instead of adding a duplicate.
            """
        )
    }

    private func makeViewModel(
        repository: AddFlowStubPantryRepository = AddFlowStubPantryRepository(),
        onPantryChanged: @escaping () -> Void = {}
    ) -> AddPantryIngredientViewModel {
        AddPantryIngredientViewModel(
            ingredientCatalogue: catalogue,
            pantryRepository: repository,
            onPantryChanged: onPantryChanged
        )
    }

    private var catalogue: [PantryIngredientOption] {
        [
            PantryIngredientOption(
                name: "Spinach",
                category: .leafyGreen,
                isCommonlyAdded: true
            ),
            PantryIngredientOption(
                name: "Chicken",
                category: .protein,
                isCommonlyAdded: true
            ),
            PantryIngredientOption(
                name: "Tofu",
                category: .protein,
                isCommonlyAdded: true
            ),
            PantryIngredientOption(
                name: "Rice",
                category: .grain,
                isCommonlyAdded: true
            )
        ]
    }
}

private final class AddFlowStubPantryRepository: PantryRepository {

    private var ingredients: [PantryIngredient]

    init(ingredients: [PantryIngredient] = []) {
        self.ingredients = ingredients
    }

    func fetchPantryIngredients() throws -> [PantryIngredient] {
        ingredients
    }

    func fetchIngredientsExpiringSoon(on date: Date) throws -> [PantryIngredient] {
        ingredients.filter { $0.isExpiringSoon(on: date) }
    }

    func addPantryIngredient(_ ingredient: PantryIngredient) throws {
        let alreadyExists = ingredients.contains {
            $0.id == ingredient.id ||
            $0.name.caseInsensitiveCompare(ingredient.name) == .orderedSame
        }

        guard !alreadyExists else {
            throw PantryRepositoryError.ingredientAlreadyExists(ingredient.name)
        }

        ingredients.append(ingredient)
    }

    func removePantryIngredient(id: IngredientID) throws {
        ingredients.removeAll { $0.id == id }
    }

    func updateExpiryDate(for id: IngredientID, expiresAt: Date?) throws {
        guard let index = ingredients.firstIndex(where: { $0.id == id }) else {
            throw PantryRepositoryError.ingredientNotFound(id)
        }

        ingredients[index].expiresAt = expiresAt
    }
}
