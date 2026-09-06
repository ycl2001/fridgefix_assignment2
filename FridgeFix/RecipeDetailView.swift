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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                readinessSection
                mealInformationSection
                ingredientsSection
                substitutionsSection
                nutritionSection
                instructionsSection
            }
            .padding()
        }
        .navigationTitle(recommendation.recipe.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var readinessSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(
                recommendation.suitability.readiness.displayName
            )
            .font(.title2)
            .fontWeight(.bold)
            .foregroundStyle(.purple)

            Text(recommendation.suitability.explanation)
                .font(.body)

            Text(
                "\(recommendation.suitability.pantryMatchPercentage)% of recipe ingredients available"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }

    private var mealInformationSection: some View {
        HStack(spacing: 16) {
            Label(
                "\(recommendation.recipe.totalCookingTimeInMinutes) minutes",
                systemImage: "clock"
            )

            Label(
                recommendation.recipe.difficulty.displayName,
                systemImage: "chart.bar"
            )
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ingredients")
                .font(.headline)

            ForEach(
                recommendation.recipe.ingredientRequirements,
                id: \.ingredientName
            ) { requirement in
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 7))

                    Text(requirement.ingredientName)

                    if requirement.isEssential {
                        Text("Essential")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !recommendation.suitability.missingIngredients.isEmpty {
                Text(
                    "Shopping needed: " +
                    recommendation.suitability.missingIngredients
                        .joined(separator: ", ")
                )
                .font(.subheadline)
                .foregroundStyle(.orange)
            }
        }
    }

    private var substitutionsSection: some View {
        Group {
            if !recommendation.suitability.substitutions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Available Substitutions")
                        .font(.headline)

                    ForEach(
                        recommendation.suitability.substitutions,
                        id: \.self
                    ) { substitution in
                        Text(
                            "\(substitution.requiredIngredient) → " +
                            "\(substitution.availableIngredient)"
                        )
                        .font(.subheadline)
                    }
                }
            }
        }
    }

    private var nutritionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nutrition Balance")
                .font(.headline)

            Text(
                recommendation.recipe.nutritionBalance
                    .rawValue
                    .replacingOccurrences(
                        of: "([a-z])([A-Z])",
                        with: "$1 $2",
                        options: .regularExpression
                    )
                    .capitalized
            )
            .font(.subheadline)
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
}
