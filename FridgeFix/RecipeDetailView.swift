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
    private let suitabilityColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: -20) {
                RecipePhotoView(
                    recipe: recommendation.recipe,
                    height: 230,
                    cornerRadius: 0
                )
                .containerRelativeFrame(.horizontal)

                contentSurface
            }
            .containerRelativeFrame(.horizontal)
        }
        .background(FridgeFixTheme.pageBackground)
        .navigationTitle("Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    applyFeedback(.saved)
                } label: {
                    Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                }
                .accessibilityLabel(
                    isSaved
                        ? "Saved for this cooking session"
                        : "Save for this cooking session"
                )
                .accessibilityHint("Saves this recipe in the current recommendation session.")
            }
        }
    }

    private var contentSurface: some View {
        VStack(alignment: .leading, spacing: 16) {
            Capsule()
                .fill(Color.secondary.opacity(0.25))
                .frame(width: 44, height: 5)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)

            recipeHeadingSection
            suitabilityIndicatorsSection
            whyThisRecipeSection
            ingredientsSection
            directionsSection
            feedbackSection
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FridgeFixTheme.cardBackground)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 24,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 24,
                style: .continuous
            )
        )
        .shadow(color: Color.black.opacity(0.08), radius: 16, y: -4)
    }

    private var recipeHeadingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            DetailRecipeReadinessBadge(
                readiness: recommendation.suitability.readiness
            )

            Text(recommendation.recipe.name)
                .font(.title2)
                .fontDesign(.rounded)
                .fontWeight(.bold)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                Label(
                    recommendation.recipe.cuisine.displayName,
                    systemImage: "globe.asia.australia"
                )

                if !recommendation.recipe.tastePreferences.isEmpty {
                    Label(tasteSummary, systemImage: "sparkles")
                }

                Label(
                    recommendation.recipe.nutritionBalance.displayName,
                    systemImage: nutritionIconName
                )
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Text(recommendation.suitability.explanation)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var suitabilityIndicatorsSection: some View {
        LazyVGrid(
            columns: suitabilityColumns,
            alignment: .leading,
            spacing: 10
        ) {
            SuitabilityIndicator(
                value: "\(recommendation.suitability.pantryMatchPercentage)%",
                label: "Pantry",
                systemImage: "refrigerator",
                tint: readinessTint
            )

            SuitabilityIndicator(
                value: "\(recommendation.recipe.totalCookingTimeInMinutes) min",
                label: "Total",
                systemImage: "clock",
                tint: .accentColor
            )

            SuitabilityIndicator(
                value: recommendation.recipe.difficulty.displayName,
                label: "Effort",
                systemImage: "chart.bar",
                tint: .accentColor
            )

            SuitabilityIndicator(
                value: shoppingIndicatorValue,
                label: "Needed",
                systemImage: shoppingIndicatorIcon,
                tint: recommendation.suitability.missingIngredients.isEmpty
                    ? .green
                    : .orange
            )
        }
    }

    private var whyThisRecipeSection: some View {
        DetailSection(title: "Why this recipe?") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(whyThisRecipeReasons, id: \.self) { reason in
                    RecommendationReasonRow(text: reason)
                }
            }
        }
    }

    private var ingredientsSection: some View {
        DetailSection(title: "Ingredients") {
            VStack(alignment: .leading, spacing: 18) {
                if !availableIngredients.isEmpty {
                    IngredientGroup(title: "Available in your pantry") {
                        ForEach(
                            availableIngredients,
                            id: \.ingredientName
                        ) { requirement in
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
                    IngredientGroup(title: "Available through substitution") {
                        ForEach(
                            recommendation.suitability.substitutions,
                            id: \.self
                        ) { substitution in
                            IngredientAvailabilityRow(
                                title: substitution.requiredIngredient,
                                detail: "\(substitution.requiredIngredient) → \(substitution.availableIngredient) available as a \(substitution.category.displayName.lowercased()) substitution",
                                systemImage: "arrow.triangle.2.circlepath.circle.fill",
                                tint: .accentColor
                            )
                        }
                    }
                }

                if !recommendation.suitability.missingIngredients.isEmpty {
                    IngredientGroup(title: "Missing and needs shopping") {
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
    }

    private var directionsSection: some View {
        DetailSection(title: "Directions") {
            VStack(alignment: .leading, spacing: 14) {
                ForEach(
                    Array(recommendation.recipe.instructions.enumerated()),
                    id: \.offset
                ) { index, instruction in
                    DirectionStepRow(
                        stepNumber: index + 1,
                        instruction: instruction
                    )
                }
            }
        }
    }

    private var feedbackSection: some View {
        DetailSection(title: "Your Response") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Feedback changes options for this cooking session only.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) {
                        saveButton
                        skipButton
                        feedbackMenu
                    }

                    VStack(spacing: 8) {
                        saveButton
                        skipButton
                        feedbackMenu
                    }
                }

                if let feedbackMessage {
                    Label(feedbackMessage, systemImage: "checkmark.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var saveButton: some View {
        Button {
            applyFeedback(.saved)
        } label: {
            Label(isSaved ? "Saved" : "Save", systemImage: "heart")
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
        }
        .buttonStyle(.borderedProminent)
    }

    private var skipButton: some View {
        Button {
            applyFeedback(.skipped)
        } label: {
            Label("Skip", systemImage: "forward")
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
        }
        .buttonStyle(.bordered)
    }

    private var feedbackMenu: some View {
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
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
        }
        .buttonStyle(.bordered)
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

    private var isSaved: Bool {
        if case .saved = session.feedback(for: recommendation.recipe.id) {
            return true
        }

        return false
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

    private var readinessTint: Color {
        switch recommendation.suitability.readiness {
        case .readyToCook:
            return .green
        case .almostReady:
            return .accentColor
        case .needsOneToTwoIngredients:
            return .orange
        }
    }

    private var shoppingIndicatorValue: String {
        let count = recommendation.suitability.missingIngredients.count

        if count == 0 {
            return "0 items"
        }

        return count == 1 ? "1 item" : "\(count) items"
    }

    private var shoppingIndicatorIcon: String {
        recommendation.suitability.missingIngredients.isEmpty
            ? "checkmark.circle.fill"
            : "cart.circle.fill"
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

/// Shows a grouped detail section within the overlapping recipe surface.
private struct DetailSection<Content: View>: View {

    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .fridgeFixSectionTitle()

            content()
        }
    }
}

/// Shows one compact recommendation suitability indicator.
private struct SuitabilityIndicator: View {

    let value: String
    let label: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(tint)
                .accessibilityHidden(true)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(7)
        .frame(minHeight: 68)
        .background(FridgeFixTheme.pageBackground)
        .clipShape(
            RoundedRectangle(
                cornerRadius: FridgeFixTheme.compactCornerRadius,
                style: .continuous
            )
        )
        .accessibilityElement(children: .combine)
    }
}

/// Shows one ingredient availability group.
private struct IngredientGroup<Content: View>: View {

    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title)
                .font(.subheadline)
                .fontDesign(.rounded)
                .fontWeight(.semibold)

            content()
        }
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
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
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
            return .accentColor
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
                .font(.subheadline)
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
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FridgeFixTheme.pageBackground)
        .clipShape(
            RoundedRectangle(
                cornerRadius: FridgeFixTheme.compactCornerRadius,
                style: .continuous
            )
        )
    }
}

/// Presents one recipe instruction as a numbered direction.
private struct DirectionStepRow: View {

    let stepNumber: Int
    let instruction: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(stepNumber)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
                .frame(width: 28, height: 28)
                .background(Color.yellow.opacity(0.35))
                .clipShape(Circle())
                .accessibilityHidden(true)

            Text(instruction)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(stepNumber). \(instruction)")
    }
}
