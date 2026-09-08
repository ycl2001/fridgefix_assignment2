//
//  RecommendationsView.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import SwiftUI

/// Displays meals ranked for the user's current cooking situation.
struct RecommendationsView: View {

    let context: CookingContext?

    @ObservedObject var viewModel: RecommendationsViewModel

    init(
        context: CookingContext? = nil,
        recommendationsViewModel: RecommendationsViewModel
    ) {
        self.context = context
        self.viewModel = recommendationsViewModel
    }

    var body: some View {
            Group {
                if viewModel.isLoading {
                    loadingState
                } else if let errorMessage = viewModel.errorMessage {
                    recommendationUnavailableState(errorMessage)
                } else {
                    recommendationList
                }
            }
            .navigationTitle("Your Meal Options")
            .background(FridgeFixTheme.pageBackground)
            .task {
                if let context {
                    viewModel.generateRecommendations(for: context)
                }
            }
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Finding realistic meals...")
                .font(.headline)
            Text("Checking your pantry, available time, preferences, and cooking constraints.")
                .font(.subheadline)
                .foregroundStyle(FridgeFixTheme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }

    private var recommendationList: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ranked using your pantry, available time, preferences, and cooking constraints.")
                        .font(.subheadline)
                        .foregroundStyle(FridgeFixTheme.secondaryText)

                    Label(
                        "Use Back to adjust your cooking situation.",
                        systemImage: "slider.horizontal.3"
                    )
                    .font(.caption)
                    .foregroundStyle(FridgeFixTheme.secondaryText)
                }
                .padding(.vertical, 4)
            }
            .listRowBackground(Color.clear)

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
                    Section {
                        ForEach(matchingRecommendations) { recommendation in
                            NavigationLink {
                                RecipeDetailView(
                                    recommendation: recommendation,
                                    session: $viewModel.session
                                ) {
                                    viewModel.regenerateCurrentRecommendations()
                                }
                            } label: {
                                RecipeRecommendationCard(
                                    recommendation: recommendation
                                )
                            }
                            .listRowBackground(Color.clear)
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(readiness.displayName)
                            Text(readiness.sectionDescription)
                                .font(.caption)
                                .foregroundStyle(FridgeFixTheme.secondaryText)
                                .textCase(nil)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(FridgeFixTheme.pageBackground)
    }

    private func recommendationUnavailableState(
        _ errorMessage: String
    ) -> some View {
        ContentUnavailableView {
            Label("No Realistic Meals", systemImage: "fork.knife")
        } description: {
            Text(errorMessage)
        } actions: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Try this next:")
                    .font(.headline)

                Label(
                    "Relax cuisine or taste preferences",
                    systemImage: "1.circle"
                )
                Label(
                    "Increase available cooking time or difficulty",
                    systemImage: "2.circle"
                )
                Label(
                    "Turn off expiry prioritisation",
                    systemImage: "3.circle"
                )
                Label(
                    "Add more pantry ingredients",
                    systemImage: "4.circle"
                )
            }
            .font(.caption)
            .foregroundStyle(FridgeFixTheme.secondaryText)
            .multilineTextAlignment(.leading)
        }
    }
}

/// Displays one explainable recipe recommendation.
private struct RecipeRecommendationCard: View {

    let recommendation: RecipeRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            RecipePhotoView(
                recipe: recommendation.recipe,
                height: 150,
                cornerRadius: 12
            )

            Text(recommendation.recipe.name)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 8) {
                RecipeReadinessBadge(
                    readiness: recommendation.suitability.readiness
                )

                Spacer(minLength: 8)

                NutritionBalanceLabel(
                    nutritionBalance: recommendation.recipe.nutritionBalance
                )
            }

            Text(recommendation.suitability.explanation)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                Label(
                    "\(recommendation.suitability.pantryMatchPercentage)% pantry match",
                    systemImage: "refrigerator"
                )

                Label(
                    "Ready in \(recommendation.recipe.totalCookingTimeInMinutes) minutes",
                    systemImage: "clock"
                )

                Label(
                    recommendation.recipe.difficulty.displayName,
                    systemImage: "chart.bar"
                )

                shoppingLabel

                if !recommendation.suitability.substitutions.isEmpty {
                    Label(
                        substitutionText,
                        systemImage: "arrow.triangle.2.circlepath"
                    )
                }

                if recommendation.suitability.usesUrgentIngredient {
                    Label(
                        "Uses an ingredient expiring soon",
                        systemImage: "clock.badge.exclamationmark"
                    )
                }
            }
            .font(.caption)
            .foregroundStyle(FridgeFixTheme.secondaryText)

            if !recommendation.rankingReasons.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(
                        recommendation.rankingReasons,
                        id: \.self
                    ) { reason in
                        Label(reason.displayText, systemImage: "checkmark.circle")
                    }
                }
                .font(.caption)
                .foregroundStyle(FridgeFixTheme.primaryAccent)
            }
        }
        .padding(12)
        .background(FridgeFixTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var shoppingLabel: some View {
        let missingIngredients =
            recommendation.suitability.missingIngredients

        if missingIngredients.isEmpty {
            return Label(
                "No extra shopping needed",
                systemImage: "checkmark.circle"
            )
        }

        return Label(
            missingIngredients.count == 1
                ? "1 ingredient needed: \(missingIngredients[0])"
                : "\(missingIngredients.count) ingredients needed: \(missingIngredients.joined(separator: ", "))",
            systemImage: "cart"
        )
    }

    private var substitutionText: String {
        recommendation.suitability.substitutions.count == 1
            ? "Substitution available"
            : "\(recommendation.suitability.substitutions.count) substitutions available"
    }
}

/// Shows the practical readiness category for a recommended recipe.
private struct RecipeReadinessBadge: View {

    let readiness: RecipeReadiness

    var body: some View {
        Label(readiness.displayName, systemImage: iconName)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(foregroundStyle)
    }

    private var iconName: String {
        switch readiness {
        case .readyToCook:
            return "checkmark.circle.fill"
        case .almostReady:
            return "arrow.triangle.2.circlepath.circle.fill"
        case .needsOneToTwoIngredients:
            return "cart.circle.fill"
        }
    }

    private var foregroundStyle: Color {
        switch readiness {
        case .readyToCook:
            return .green
        case .almostReady:
            return FridgeFixTheme.primaryAccent
        case .needsOneToTwoIngredients:
            return FridgeFixTheme.urgentAccent
        }
    }
}

/// Displays the recipe's simple nutrition-balance signal.
private struct NutritionBalanceLabel: View {

    let nutritionBalance: NutritionBalance

    var body: some View {
        Label(nutritionBalance.displayName, systemImage: iconName)
            .font(.caption)
            .foregroundStyle(FridgeFixTheme.secondaryText)
            .labelStyle(.iconOnly)
            .accessibilityLabel(nutritionBalance.displayName)
    }

    private var iconName: String {
        switch nutritionBalance {
        case .balanced:
            return "fork.knife.circle.fill"
        case .partlyBalanced:
            return "fork.knife.circle"
        case .limitedBalance:
            return "exclamationmark.circle"
        }
    }
}
