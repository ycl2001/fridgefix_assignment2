//
//  RecipeDetailView.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import SwiftUI

/// Shows the practical information a user needs before choosing a meal.
struct RecipeDetailView: View {

    let recommendation: RecipeRecommendation
    @Binding var session: RecommendationSession
    let onFeedbackApplied: () -> Void

    @State private var feedbackMessage: String?
    @Environment(\.dismiss) private var dismiss

    private let feedbackUseCase = ApplySessionRecipeFeedbackUseCase()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                RecipePhotoView(
                    recipe: recommendation.recipe,
                    height: 240,
                    cornerRadius: 14
                )

                recipeSummarySection
                whyThisRecipeSection
                feedbackSection
                ingredientsSection
                instructionsSection
            }
            .padding()
        }
        .navigationTitle(recommendation.recipe.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Response")
                .font(.headline)

            Text("Feedback changes options for this cooking session only.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button {
                    applyFeedback(.saved)
                } label: {
                    Label("Save", systemImage: "heart")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    applyFeedback(.skipped)
                } label: {
                    Label("Skip", systemImage: "forward")
                }
                .buttonStyle(.bordered)

                Menu {
                    ForEach(
                        SessionRecipeFeedbackReason.allCases,
                        id: \.rawValue
                    ) { reason in
                        Button(reason.displayText) {
                            applyFeedback(.reported(reason))
                        }
                    }
                } label: {
                    Label("Feedback", systemImage: "text.bubble")
                }
                .buttonStyle(.bordered)
            }
            .fixedSize(horizontal: false, vertical: true)

            if let feedbackMessage {
                Label(feedbackMessage, systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var recipeSummarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.purple)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text(recommendation.recipe.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .fixedSize(horizontal: false, vertical: true)

                    DetailRecipeReadinessBadge(
                        readiness: recommendation.suitability.readiness
                    )
                }
            }

            Text(recommendation.suitability.explanation)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 8) {
                Label(
                    "Ready in \(recommendation.recipe.totalCookingTimeInMinutes) minutes",
                    systemImage: "clock"
                )

                Label(
                    recommendation.recipe.difficulty.displayName,
                    systemImage: "chart.bar"
                )

                Label(
                    recommendation.recipe.cuisine.displayName,
                    systemImage: "globe.asia.australia"
                )

                if !recommendation.recipe.tastePreferences.isEmpty {
                    Label(
                        tasteSummary,
                        systemImage: "sparkles"
                    )
                }

                Label(
                    recommendation.recipe.nutritionBalance.displayName,
                    systemImage: nutritionIconName
                )
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var whyThisRecipeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Why this recipe?")
                .font(.headline)

            ForEach(whyThisRecipeReasons, id: \.self) { reason in
                RecommendationReasonRow(text: reason)
            }
        }
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Ingredients")
                .font(.headline)

            if !availableIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available in your pantry")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(availableIngredients, id: \.ingredientName) { requirement in
                        IngredientAvailabilityRow(
                            title: requirement.ingredientName,
                            detail: requirement.isEssential
                                ? "Essential ingredient available"
                                : "Optional ingredient available",
                            systemImage: "checkmark.circle.fill",
                            tint: .green
                        )
                    }
                }
            }

            if !recommendation.suitability.substitutions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available through substitution")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(
                        recommendation.suitability.substitutions,
                        id: \.self
                    ) { substitution in
                        IngredientAvailabilityRow(
                            title: substitution.requiredIngredient,
                            detail: "\(substitution.requiredIngredient) → \(substitution.availableIngredient) available as a \(substitution.category.displayName.lowercased()) substitution",
                            systemImage: "arrow.triangle.2.circlepath.circle.fill",
                            tint: .purple
                        )
                    }
                }
            }

            if !recommendation.suitability.missingIngredients.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Missing and needs shopping")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(
                        recommendation.suitability.missingIngredients,
                        id: \.self
                    ) { ingredient in
                        IngredientAvailabilityRow(
                            title: ingredient,
                            detail: "Needed before cooking this meal",
                            systemImage: "cart.circle.fill",
                            tint: .orange
                        )
                    }
                }
            }
        }
    }

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Instructions")
                .font(.headline)

            ForEach(
                Array(
                    recommendation.recipe.instructions.enumerated()
                ),
                id: \.offset
            ) { index, instruction in
                HStack(alignment: .top) {
                    Text("\(index + 1).")
                        .fontWeight(.bold)

                    Text(instruction)
                }
            }
        }
    }

    private func applyFeedback(
        _ action: SessionRecipeFeedbackAction
    ) {
        var updatedSession = session

        let feedback = SessionRecipeFeedback(
            recipeID: recommendation.recipe.id,
            action: action
        )

        do {
            try feedbackUseCase.execute(
                feedback: feedback,
                in: &updatedSession
            )

            session = updatedSession
            onFeedbackApplied()

            switch action {
            case .saved:
                feedbackMessage = "Saved for this cooking session."

            case .skipped:
                feedbackMessage = "Removed from this cooking session."
                dismiss()

            case .reported(let reason):
                feedbackMessage = "\(reason.displayText). We'll adjust your options for this cooking session."
            }
        } catch {
            feedbackMessage = "Feedback could not be recorded."
        }
    }

    private var tasteSummary: String {
        recommendation.recipe.tastePreferences
            .map(\.displayName)
            .sorted()
            .joined(separator: ", ")
    }

    private var nutritionIconName: String {
        switch recommendation.recipe.nutritionBalance {
        case .balanced:
            return "fork.knife.circle.fill"
        case .partlyBalanced:
            return "fork.knife.circle"
        case .limitedBalance:
            return "exclamationmark.circle"
        }
    }

    private var availableIngredients: [RecipeIngredientRequirement] {
        let missingNames = Set(
            recommendation.suitability.missingIngredients.map {
                normalise($0)
            }
        )
        let substitutedNames = Set(
            recommendation.suitability.substitutions.map {
                normalise($0.requiredIngredient)
            }
        )

        return recommendation.recipe.ingredientRequirements.filter {
            !missingNames.contains(normalise($0.ingredientName)) &&
            !substitutedNames.contains(normalise($0.ingredientName))
        }
    }

    private var whyThisRecipeReasons: [String] {
        var reasons: [String] = []
        let availableCount = availableIngredients.count +
            recommendation.suitability.substitutions.count
        let totalCount = recommendation.recipe.ingredientRequirements.count

        reasons.append(
            "You already have or can substitute \(availableCount) of the \(totalCount) recipe ingredients."
        )

        for reason in recommendation.rankingReasons {
            reasons.append(reason.displayText)
        }

        if recommendation.suitability.usesUrgentIngredient {
            reasons.append("Uses an ingredient expiring soon.")
        }

        if recommendation.suitability.missingIngredients.count == 1,
           let missingIngredient = recommendation.suitability.missingIngredients.first {
            reasons.append("Only \(missingIngredient) is missing.")
        } else if recommendation.suitability.missingIngredients.count > 1 {
            reasons.append(
                "Only \(recommendation.suitability.missingIngredients.joined(separator: ", ")) are missing."
            )
        }

        for substitution in recommendation.suitability.substitutions {
            reasons.append(
                "\(substitution.availableIngredient) can replace \(substitution.requiredIngredient) as a \(substitution.category.displayName.lowercased()) ingredient."
            )
        }

        return Array(
            NSOrderedSet(array: reasons)
        ) as? [String] ?? reasons
    }

    private func normalise(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}

/// Shows the recommendation readiness state with both text and iconography.
private struct DetailRecipeReadinessBadge: View {

    let readiness: RecipeReadiness

    var body: some View {
        Label(readiness.displayName, systemImage: iconName)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(tint)
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

    private var tint: Color {
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

/// Displays one reason supporting the selected recommendation.
private struct RecommendationReasonRow: View {

    let text: String

    var body: some View {
        Label(text, systemImage: "checkmark.circle")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// Displays how one recipe ingredient is satisfied for the current recommendation.
private struct IngredientAvailabilityRow: View {

    let title: String
    let detail: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
