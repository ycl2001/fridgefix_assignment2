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
    @State private var isReadinessGuidePresented = false

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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isReadinessGuidePresented = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel("Readiness guide")
                    .accessibilityHint("Explains the meal readiness symbols.")
                }
            }
            .sheet(isPresented: $isReadinessGuidePresented) {
                ReadinessGuideView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
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
                .fridgeFixSectionTitle()
            Text("Checking your pantry, available time, preferences, and cooking constraints.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FridgeFixTheme.pageBackground)
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
                .listRowBackground(FridgeFixTheme.cardBackground)
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
                                .fridgeFixSectionTitle()
                            Text(readiness.sectionDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                        }
                    }
                    .listRowBackground(FridgeFixTheme.cardBackground)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(FridgeFixTheme.pageBackground)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 12)
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
                    .fridgeFixSectionTitle()

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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FridgeFixTheme.pageBackground)
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
                cornerRadius: FridgeFixTheme.compactCornerRadius
            )

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        RecipeReadinessIcon(
                            readiness: recommendation.suitability.readiness
                        )

                        Text(recommendation.recipe.name)
                            .fridgeFixCardTitle()
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                CompactRecommendationMetricStrip(facts: compactFacts)

                Label(shoppingSummaryText, systemImage: shoppingSummaryIcon)
                    .font(.caption)
                    .foregroundStyle(shoppingSummaryColor)
                    .padding(.top, 6)
                    .fixedSize(horizontal: false, vertical: true)
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

    private var compactFacts: [CompactRecommendationFact] {
        [
            CompactRecommendationFact(
                value: "\(recommendation.suitability.pantryMatchPercentage)%",
                label: "Pantry",
                systemImage: "refrigerator",
                accessibilityLabel: "\(recommendation.suitability.pantryMatchPercentage) percent pantry match"
            ),
            CompactRecommendationFact(
                value: "\(recommendation.recipe.totalCookingTimeInMinutes) min",
                label: "Total",
                systemImage: "clock",
                accessibilityLabel: "\(recommendation.recipe.totalCookingTimeInMinutes) minutes total cooking time"
            ),
            CompactRecommendationFact(
                value: recommendation.recipe.difficulty.displayName,
                label: "Effort",
                systemImage: "chart.bar",
                accessibilityLabel: "\(recommendation.recipe.difficulty.displayName) cooking difficulty"
            )
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

/// Groups compact recommendation facts inside one shared metric surface.
private struct CompactRecommendationMetricStrip: View {

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let facts: [CompactRecommendationFact]

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                LazyVGrid(columns: accessibilityColumns, spacing: 10) {
                    ForEach(facts) { fact in
                        CompactRecommendationFactColumn(fact: fact)
                    }
                }
            } else {
                HStack(spacing: 0) {
                    ForEach(Array(facts.enumerated()), id: \.element.id) { index, fact in
                        CompactRecommendationFactColumn(fact: fact)

                        if index < facts.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 8)
        .background(
            FridgeFixTheme.pageBackground,
            in: RoundedRectangle(cornerRadius: FridgeFixTheme.compactCornerRadius)
        )
    }

    private var accessibilityColumns: [GridItem] {
        [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ]
    }
}

/// One compact recommendation metric displayed inside the shared metric strip.
private struct CompactRecommendationFact: Identifiable {

    let id = UUID()
    let value: String
    let label: String
    let systemImage: String
    let accessibilityLabel: String
}

private struct CompactRecommendationFactColumn: View {

    let fact: CompactRecommendationFact

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: fact.systemImage)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(fact.value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(2)

            Text(fact.label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(fact.accessibilityLabel)
    }
}

/// Shows only the readiness symbol for compact recommendation cards.
private struct RecipeReadinessIcon: View {

    let readiness: RecipeReadiness

    var body: some View {
        Image(systemName: iconName)
            .font(.system(size: 19, weight: .semibold))
            .foregroundStyle(foregroundStyle)
            .accessibilityLabel(readiness.displayName)
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
            return FridgeFixTheme.brandAccent
        case .needsOneToTwoIngredients:
            return .orange
        }
    }
}

/// Explains the readiness symbols used by compact recommendation cards.
private struct ReadinessGuideView: View {

    private let rows: [(readiness: RecipeReadiness, description: String)] = [
        (
            .readyToCook,
            "The essential ingredients are available, or accepted substitutions make the recipe immediately practical."
        ),
        (
            .almostReady,
            "One minor ingredient is unavailable, but an accepted pantry substitution can be used."
        ),
        (
            .needsOneToTwoIngredients,
            "A small amount of additional shopping is required before cooking."
        )
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(rows, id: \.readiness) { row in
                    HStack(alignment: .top, spacing: 12) {
                        RecipeReadinessIcon(readiness: row.readiness)
                            .frame(width: 28, height: 28)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.readiness.displayName)
                                .fridgeFixCardTitle()

                            Text(row.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .scrollContentBackground(.hidden)
            .background(FridgeFixTheme.pageBackground)
            .navigationTitle("What do these symbols mean?")
            .navigationBarTitleDisplayMode(.inline)
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
