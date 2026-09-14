//
//  RecommendationViewModel.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation
import Combine

/// Provides ranked meal recommendations and recommendation state to SwiftUI.
@MainActor
final class RecommendationsViewModel: ObservableObject {

    @Published private(set) var recommendations: [RecipeRecommendation] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var recoveryActions: [String] = []
    @Published private(set) var isLoading = false
    @Published private(set) var currentContext: CookingContext?
    @Published var session = RecommendationSession()

    private let recommendationUseCase:
        GenerateContextAwareRecommendationsUseCase

    init(
        recommendationUseCase:
            GenerateContextAwareRecommendationsUseCase =
            GenerateContextAwareRecommendationsUseCase(
                recipeRepository: LocalRecipeRepository(),
                pantryRepository: LocalPantryRepository.shared
            )
    ) {
        self.recommendationUseCase = recommendationUseCase
    }

    /// Generates recommendations for the user's current cooking context.
    func generateRecommendations(
        for context: CookingContext
    ) {
        isLoading = true
        errorMessage = nil
        recoveryActions = []
        currentContext = context

        do {
            recommendations = try recommendationUseCase.execute(
                context: context,
                session: session
            )
            recoveryActions = []
        } catch let recommendationError as RecommendationGenerationError {
            recommendations = []
            errorMessage = recoveryMessage(for: recommendationError)
            recoveryActions = recoveryActions(for: recommendationError)
        } catch {
            recommendations = []
            errorMessage = """
            FridgeFix could not generate recommendations.
            Please try again.
            """
            recoveryActions = ["Try again in a moment"]
        }

        isLoading = false
    }

    var hasRecommendations: Bool {
        !recommendations.isEmpty
    }

    /// Regenerates the current meal options using the last cooking context.
    func regenerateCurrentRecommendations() {
        guard let currentContext else {
            return
        }

        generateRecommendations(for: currentContext)
    }

    private func recoveryMessage(
        for error: RecommendationGenerationError
    ) -> String {
        [
            error.errorDescription,
            error.recoverySuggestion
        ]
        .compactMap { $0 }
        .joined(separator: "\n")
    }

    private func recoveryActions(
        for error: RecommendationGenerationError
    ) -> [String] {
        switch error {
        case .pantryInformationUnavailable:
            return ["Refresh your pantry", "Try again"]
        case .pantryNeedsIngredients:
            return ["Add pantry ingredients", "Try again after adding food"]
        case .recipeCatalogueUnavailable:
            return ["Try again in a moment"]
        case .recipeInformationIncomplete:
            return ["Try again after recipe information is updated"]
        case .filtersExcludeFeasibleRecipes:
            return [
                "Relax cuisine or taste preferences",
                "Increase available cooking time or difficulty",
                "Review dietary restrictions"
            ]
        case .noRealisticallySuitableRecipes:
            return [
                "Add more pantry ingredients",
                "Allow meals that need one or two additions"
            ]
        }
    }
}
