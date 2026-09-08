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
                .foregroundStyle(.secondary)
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
                        .foregroundStyle(.secondary)

                    Label(
                        "Use Back to adjust your cooking situation.",
                        systemImage: "slider.horizontal.3"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

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
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(readiness.displayName)
                            Text(readiness.sectionDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                        }
                    }
                }
            }
        }
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
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
        }
    }
}

/// Displays one explainable recipe recommendation.
private struct RecipeRecommendationCard: View {

    let recommendation: RecipeRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RecipePhotoView(
                recipe: recommendation.recipe,
                height: 110,
                cornerRadius: 10
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    Text(recommendation.recipe.name)
                        .font(.headline)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 8)

                    RecipeReadinessBadge(
                        readiness: recommendation.suitability.readiness
                    )
                }

                LazyVGrid(
                    columns: compactFactColumns,
                    alignment: .leading,
                    spacing: 6
                ) {
                    CompactRecommendationFact(
                        text: "\(recommendation.suitability.pantryMatchPercentage)% pantry",
                        systemImage: "refrigerator",
                        accessibilityLabel: "\(recommendation.suitability.pantryMatchPercentage) percent pantry match"
                    )

                    CompactRecommendationFact(
                        text: "\(recommendation.recipe.totalCookingTimeInMinutes) min",
                        systemImage: "clock",
                        accessibilityLabel: "\(recommendation.recipe.totalCookingTimeInMinutes) minutes total cooking time"
                    )

                    CompactRecommendationFact(
                        text: recommendation.recipe.difficulty.displayName,
                        systemImage: "chart.bar",
                        accessibilityLabel: "\(recommendation.recipe.difficulty.displayName) cooking difficulty"
                    )
                }

                Label(shoppingSummaryText, systemImage: shoppingSummaryIcon)
                    .font(.caption)
                    .foregroundStyle(shoppingSummaryColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                    .accessibilityLabel(shoppingSummaryText)

                if let primaryReasonText {
                    Label(
                        primaryReasonText,
                        systemImage: primaryReasonIcon
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(primaryReasonText)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var compactFactColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 84), spacing: 8)
        ]
    }

    private var shoppingSummaryText: String {
        if recommendation.suitability.readiness == .almostReady,
           !recommendation.suitability.substitutions.isEmpty {
            return "Substitution available"
        }

        switch recommendation.suitability.missingIngredients.count {
        case 0:
            return "No shopping needed"
        case 1:
            return "1 ingredient needed"
        default:
            return "\(recommendation.suitability.missingIngredients.count) ingredients needed"
        }
    }

    private var shoppingSummaryIcon: String {
        if recommendation.suitability.readiness == .almostReady,
           !recommendation.suitability.substitutions.isEmpty {
            return "arrow.triangle.2.circlepath"
        }

        return recommendation.suitability.missingIngredients.isEmpty
            ? "checkmark.circle"
            : "cart"
    }

    private var shoppingSummaryColor: Color {
        recommendation.suitability.missingIngredients.isEmpty ? .secondary : .orange
    }

    private var primaryReasonText: String? {
        if recommendation.suitability.usesUrgentIngredient,
           recommendation.rankingReasons.first != .usesIngredientExpiringSoon {
            return RecommendationReason.usesIngredientExpiringSoon.displayText
        }

        return recommendation.rankingReasons.first?.displayText
    }

    private var primaryReasonIcon: String {
        primaryReasonText == RecommendationReason.usesIngredientExpiringSoon.displayText
            ? "clock.badge.exclamationmark"
            : "checkmark.circle"
    }
}

/// Shows one compact recommendation fact without expanding the result card.
private struct CompactRecommendationFact: View {

    let text: String
    let systemImage: String
    let accessibilityLabel: String

    var body: some View {
        Label {
            Text(text)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .accessibilityLabel(accessibilityLabel)
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
            return .purple
        case .needsOneToTwoIngredients:
            return .orange
        }
    }
}

/// Displays the recipe's simple nutrition-balance signal.
private struct NutritionBalanceLabel: View {

    let nutritionBalance: NutritionBalance

    var body: some View {
        Label(nutritionBalance.displayName, systemImage: iconName)
            .font(.caption)
            .foregroundStyle(.secondary)
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
