//
//  HomeView.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 8/9/2026.
//

import SwiftUI

/// Presents the domain-centred starting point for FridgeFix.
struct HomeView: View {

    @ObservedObject var pantryViewModel: PantryViewModel
    @ObservedObject var recommendationsViewModel: RecommendationsViewModel
    @Binding var selectedTab: FridgeFixTab

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    primaryDecisionEntry
                    forYouSection
                    useSoonSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("FridgeFix")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                pantryViewModel.loadPantry()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("FridgeFix")
                .font(.title2)
                .fontWeight(.bold)

            Text("Make the most of what you already have.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var primaryDecisionEntry: some View {
        Group {
            if pantryViewModel.hasPantryIngredients {
                NavigationLink {
                    CookingContextView(
                        recommendationsViewModel: recommendationsViewModel
                    )
                } label: {
                    HomePrimaryActionCard()
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    selectedTab = .pantry
                } label: {
                    HomeEmptyPantryCard()
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var forYouSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("For You")
                .font(.headline)

            if recommendationsViewModel.isLoading {
                HomeLoadingCard()
            } else if let errorMessage = recommendationsViewModel.errorMessage {
                HomeMessageCard(
                    title: "Meal options unavailable",
                    message: errorMessage,
                    systemImage: "exclamationmark.triangle"
                ) {
                    recommendationsViewModel
                        .regenerateCurrentRecommendations()
                }
            } else if recommendationsViewModel.hasRecommendations {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(
                            Array(
                                recommendationsViewModel.recommendations
                                    .prefix(3)
                            )
                        ) { recommendation in
                            NavigationLink {
                                RecipeDetailView(
                                    recommendation: recommendation,
                                    session: $recommendationsViewModel.session
                                ) {
                                    recommendationsViewModel
                                        .regenerateCurrentRecommendations()
                                }
                            } label: {
                                HomeRecommendationCard(
                                    recommendation: recommendation
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.trailing)
                }
            } else {
                HomeNoRecommendationsCard(
                    recommendationsViewModel: recommendationsViewModel
                )
            }
        }
    }

    private var useSoonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Use Soon")
                .font(.headline)

            if let errorMessage = pantryViewModel.errorMessage {
                HomeMessageCard(
                    title: "Pantry unavailable",
                    message: errorMessage,
                    systemImage: "exclamationmark.triangle"
                ) {
                    pantryViewModel.loadPantry()
                }
            } else if pantryViewModel.ingredientsExpiringSoon.isEmpty {
                HomeMessageCard(
                    title: "Nothing needs urgent attention",
                    message: "No pantry ingredients expire today or within the next two days.",
                    systemImage: "checkmark.circle"
                )
            } else {
                VStack(spacing: 10) {
                    ForEach(
                        pantryViewModel.ingredientsExpiringSoon
                    ) { ingredient in
                        HomeUrgentIngredientRow(
                            ingredient: ingredient
                        ) {
                            NavigationLink {
                                CookingContextView(
                                    recommendationsViewModel:
                                        recommendationsViewModel
                                )
                            } label: {
                                Label(
                                    "Find meals",
                                    systemImage: "sparkles"
                                )
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }
        }
    }
}

/// Displays the main FridgeFix meal-decision entry point.
private struct HomePrimaryActionCard: View {

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.title2)
                .foregroundStyle(.purple)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text("What can I cook?")
                    .font(.headline)

                Text("Use your pantry and current cooking context")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// Explains why meal decisions are unavailable until the pantry has content.
private struct HomeEmptyPantryCard: View {

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "refrigerator")
                .font(.title2)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text("Add pantry ingredients first")
                    .font(.headline)

                Text("Add a few pantry ingredients before finding meal options.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label("Open Pantry", systemImage: "cabinet")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.purple)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// Shows that recommendations are currently being generated.
private struct HomeLoadingCard: View {

    var body: some View {
        HStack(spacing: 10) {
            ProgressView()

            Text("Finding realistic meal options...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// Encourages the user to create context-aware recommendations.
private struct HomeNoRecommendationsCard: View {

    @ObservedObject var recommendationsViewModel: RecommendationsViewModel

    var body: some View {
        NavigationLink {
            CookingContextView(
                recommendationsViewModel: recommendationsViewModel
            )
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Label("Find realistic meal options", systemImage: "fork.knife")
                    .font(.headline)

                Text("Tell FridgeFix how much time you have and what you feel like eating.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Get recommendations")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.purple)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

/// Shows one previously generated recommendation in Home.
private struct HomeRecommendationCard: View {

    let recommendation: RecipeRecommendation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                recommendation.suitability.readiness.displayName,
                systemImage: "checkmark.circle"
            )
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.purple)

            Text(recommendation.recipe.name)
                .font(.headline)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Label(
                "\(recommendation.suitability.pantryMatchPercentage)% pantry match",
                systemImage: "refrigerator"
            )

            Label(
                "Ready in \(recommendation.recipe.totalCookingTimeInMinutes) minutes",
                systemImage: "clock"
            )

            if !recommendation.suitability.missingIngredients.isEmpty {
                Label(
                    "\(recommendation.suitability.missingIngredients.count) ingredient needed",
                    systemImage: "cart"
                )
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(width: 220, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

/// Displays one urgent pantry ingredient on Home.
private struct HomeUrgentIngredientRow<Action: View>: View {

    let ingredient: PantryIngredient
    @ViewBuilder let action: () -> Action

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "clock.badge.exclamationmark")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(ingredient.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(expiryDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Use soon")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            Spacer(minLength: 8)

            action()
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var expiryDescription: String {
        guard let expiresAt = ingredient.expiresAt else {
            return "Expiry date unavailable"
        }

        return "Expires \(expiresAt.formatted(date: .abbreviated, time: .omitted))"
    }
}

/// Presents a lightweight Home message with an optional recovery action.
private struct HomeMessageCard: View {

    let title: String
    let message: String
    let systemImage: String
    var action: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let action {
                Button {
                    action()
                } label: {
                    Label("Try again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    HomeView(
        pantryViewModel: PantryViewModel(),
        recommendationsViewModel: RecommendationsViewModel(),
        selectedTab: .constant(.home)
    )
}
