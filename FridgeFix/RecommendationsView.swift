//
//  RecommendationsView.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import SwiftUI

/// Displays meals ranked for the user's current cooking situation.
struct RecommendationsView: View {

    let context: CookingContext

    @StateObject private var viewModel = RecommendationsViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Finding meals you can cook...")
                } else if let errorMessage = viewModel.errorMessage {
                    ContentUnavailableView(
                        "No Suitable Meals",
                        systemImage: "fork.knife",
                        description: Text(errorMessage)
                    )
                } else {
                    recommendationList
                }
            }
            .navigationTitle("Meals You Can Cook")
            .task {
                viewModel.generateRecommendations(for: context)
            }
        }
    }

    private var recommendationList: some View {
        List {
            ForEach(
                [
                    RecipeReadiness.readyToCook,
                    RecipeReadiness.almostReady,
                    RecipeReadiness.needsOneToTwoIngredients
                ],
                id: \.self
            ) { readiness in

                let matchingRecommendations = viewModel.recommendations
                    .filter {
                        $0.suitability.readiness == readiness
                    }

                if !matchingRecommendations.isEmpty {
                    Section(readiness.displayName) {
                        ForEach(matchingRecommendations) { recommendation in
                            NavigationLink {
                                RecommendationDetailPlaceholderView(
                                    recommendation: recommendation
                                )
                            } label: {
                                RecommendationCard(
                                    recommendation: recommendation
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

/// Temporary destination until recipe details are introduced.
private struct RecommendationDetailPlaceholderView: View {

    let recommendation: RecipeRecommendation

    var body: some View {
        ContentUnavailableView(
            recommendation.recipe.name,
            systemImage: "book.pages",
            description: Text(recommendation.suitability.explanation)
        )
    }
}

/// Displays one explainable recipe recommendation.
private struct RecommendationCard: View {

    let recommendation: RecipeRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(recommendation.recipe.name)
                .font(.headline)

            HStack {
                Label(
                    "\(recommendation.suitability.pantryMatchPercentage)% pantry match",
                    systemImage: "refrigerator"
                )

                Spacer()

                Label(
                    "\(recommendation.recipe.totalCookingTimeInMinutes) min",
                    systemImage: "clock"
                )
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text(recommendation.suitability.explanation)
                .font(.subheadline)

            ForEach(
                recommendation.rankingReasons,
                id: \.self
            ) { reason in
                Text(reason.displayText)
                    .font(.caption)
                    .foregroundStyle(.purple)
            }

            if !recommendation.suitability.missingIngredients.isEmpty {
                Text(
                    "Missing: " +
                    recommendation.suitability.missingIngredients
                        .joined(separator: ", ")
                )
                .font(.caption)
                .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 6)
    }
}
