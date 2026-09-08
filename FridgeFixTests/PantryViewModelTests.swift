//
//  PantryViewModelTests.swift
//  FridgeFixTests
//
//  Created by Codex on 8/9/2026.
//

import Foundation
import Testing
@testable import FridgeFix

@MainActor
struct PantryViewModelTests {

    @Test
    func ingredientNameSearchFiltersPantryCorrectly() {
        let viewModel = makeViewModel()

        viewModel.searchText = "spin"

        #expect(viewModel.visibleIngredients.map(\.name) == ["Spinach"])
    }

    @Test
    func urgentIngredientBecomesFeaturedIngredient() {
        let viewModel = makeViewModel()

        #expect(viewModel.featuredIngredient?.name == "Spinach")
    }

    @Test
    func nonUrgentFallbackIsFeaturedWhenNoIngredientIsUrgent() {
        let viewModel = PantryViewModel(
            pantryRepository: StubPantryRepository(
                ingredients: [
                    PantryIngredient(
                        id: IngredientID(rawValue: "rice"),
                        name: "Rice",
                        substitutionCategory: .grain,
                        expiresAt: nil
                    ),
                    PantryIngredient(
                        id: IngredientID(rawValue: "chicken"),
                        name: "Chicken",
                        substitutionCategory: .protein,
                        expiresAt: Date().addingTimeInterval(60 * 60 * 24 * 5)
                    )
                ]
            )
        )
        viewModel.loadPantry()

        #expect(viewModel.featuredIngredient?.name == "Rice")
    }

    @Test
    func categoryFilteringReturnsOnlyMatchingIngredients() {
        let viewModel = makeViewModel()

        viewModel.selectedCategory = .protein

        #expect(viewModel.visibleIngredients.map(\.name) == ["Chicken"])
    }

    @Test
    func searchAndCategoryFiltersWorkTogether() {
        let viewModel = makeViewModel()

        viewModel.searchText = "rice"
        viewModel.selectedCategory = .grain

        #expect(viewModel.visibleIngredients.map(\.name) == ["Rice"])
    }

    @Test
    func clearingFiltersRestoresVisiblePantry() {
        let viewModel = makeViewModel()
        viewModel.searchText = "spin"
        viewModel.selectedCategory = .leafyGreen

        viewModel.clearFilters()

        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.selectedCategory == nil)
        #expect(viewModel.visibleIngredients.map(\.name) == pantryIngredients.map(\.name))
    }

    @Test
    func featuredIngredientIsNotDuplicatedInVisibleIngredientCards() {
        let viewModel = makeViewModel()

        #expect(viewModel.featuredIngredient?.name == "Spinach")
        #expect(viewModel.visibleIngredientsExcludingFeatured.map(\.name) == [
            "Rice",
            "Chicken"
        ])
    }

    @Test
    func unmatchedSearchProducesFilteredEmptyPresentationState() {
        let viewModel = makeViewModel()

        viewModel.searchText = "mango"

        #expect(viewModel.visibleIngredients.isEmpty)
        #expect(viewModel.isShowingFilteredEmptyState)
    }

    private func makeViewModel() -> PantryViewModel {
        let viewModel = PantryViewModel(
            pantryRepository: StubPantryRepository(ingredients: pantryIngredients)
        )
        viewModel.loadPantry()
        return viewModel
    }

    private var pantryIngredients: [PantryIngredient] {
        [
            PantryIngredient(
                id: IngredientID(rawValue: "spinach"),
                name: "Spinach",
                substitutionCategory: .leafyGreen,
                expiresAt: Date().addingTimeInterval(60 * 60 * 24)
            ),
            PantryIngredient(
                id: IngredientID(rawValue: "rice"),
                name: "Rice",
                substitutionCategory: .grain,
                expiresAt: nil
            ),
            PantryIngredient(
                id: IngredientID(rawValue: "chicken"),
                name: "Chicken",
                substitutionCategory: .protein,
                expiresAt: nil
            )
        ]
    }
}

private final class StubPantryRepository: PantryRepository {

    private var ingredients: [PantryIngredient]

    init(ingredients: [PantryIngredient]) {
        self.ingredients = ingredients
    }

    func fetchPantryIngredients() throws -> [PantryIngredient] {
        ingredients
    }

    func fetchIngredientsExpiringSoon(on date: Date) throws -> [PantryIngredient] {
        ingredients.filter { $0.isExpiringSoon(on: date) }
    }

    func addPantryIngredient(_ ingredient: PantryIngredient) throws {
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
