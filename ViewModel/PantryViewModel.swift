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

    private let pantryRepository: any PantryRepository

    init(
        pantryRepository: any PantryRepository = LocalPantryRepository()
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

    /// Indicates whether the user has enough pantry information to continue.
    var hasPantryIngredients: Bool {
        !ingredients.isEmpty
    }
}
