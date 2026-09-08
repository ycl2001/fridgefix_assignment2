//
//  CookingContentView.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import SwiftUI

/// Collects the user's current cooking limits and meal preferences.
struct CookingContextView: View {

    @ObservedObject var recommendationsViewModel: RecommendationsViewModel

    @State private var maximumCookingTime: CookingTimeLimit = .thirtyMinutes
    @State private var maximumDifficulty: CookingDifficulty = .moderate
    @State private var preferredCuisines: Set<Cuisine> = [.asian]
    @State private var preferredTastes: Set<TastePreference> = [.savoury]
    @State private var dietaryRestrictions: Set<DietaryRestriction> = []
    @State private var prioritisesExpiringIngredients = true
    private let preferenceColumns = [
        GridItem(.adaptive(minimum: 140), spacing: 8)
    ]

    init(recommendationsViewModel: RecommendationsViewModel) {
        self.recommendationsViewModel = recommendationsViewModel
    }

    var body: some View {
            Form {
                Section {
                    Text("Tell FridgeFix what cooking realistically looks like right now. Hard limits filter recipes; preferences only influence ranking.")
                        .font(.subheadline)
                        .foregroundStyle(FridgeFixTheme.secondaryText)
                }

                Section {
                    Picker(
                        "Total prep and cooking time",
                        selection: $maximumCookingTime
                    ) {
                        ForEach(CookingTimeLimit.allCases, id: \.self) { timeLimit in
                            Text(timeLimit.displayName)
                                .tag(timeLimit)
                        }
                    }
                } header: {
                    ContextSectionHeader(
                        title: "How much time do you have?",
                        detail: "This is the total time for preparation and cooking."
                    )
                }

                Section {
                    Picker(
                        "Maximum effort",
                        selection: $maximumDifficulty
                    ) {
                        ForEach(CookingDifficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.displayName)
                                .tag(difficulty)
                        }
                    }
                } header: {
                    ContextSectionHeader(
                        title: "How much effort suits you today?",
                        detail: "FridgeFix excludes meals above this difficulty."
                    )
                }

                Section {
                    LazyVGrid(
                        columns: preferenceColumns,
                        alignment: .leading,
                        spacing: 8
                    ) {
                        ForEach(Cuisine.allCases, id: \.self) { cuisine in
                            SelectablePreferenceChip(
                                title: cuisine.displayName,
                                isSelected: preferredCuisines.contains(cuisine)
                            ) {
                                toggle(cuisine, in: &preferredCuisines)
                            }
                        }
                    }
                } header: {
                    ContextSectionHeader(
                        title: "What cuisine do you feel like?",
                        detail: "Optional preference. Other practical meals can still appear."
                    )
                }

                Section {
                    LazyVGrid(
                        columns: preferenceColumns,
                        alignment: .leading,
                        spacing: 8
                    ) {
                        ForEach(TastePreference.allCases, id: \.self) { taste in
                            SelectablePreferenceChip(
                                title: taste.displayName,
                                isSelected: preferredTastes.contains(taste)
                            ) {
                                toggle(taste, in: &preferredTastes)
                            }
                        }
                    }
                } header: {
                    ContextSectionHeader(
                        title: "What flavours do you prefer?",
                        detail: "Taste affects ranking, not whether a meal is allowed."
                    )
                }

                Section {
                    LazyVGrid(
                        columns: preferenceColumns,
                        alignment: .leading,
                        spacing: 8
                    ) {
                        ForEach(DietaryRestriction.allCases, id: \.self) { restriction in
                            SelectablePreferenceChip(
                                title: restriction.displayName,
                                isSelected: dietaryRestrictions.contains(
                                    restriction
                                )
                            ) {
                                toggle(restriction, in: &dietaryRestrictions)
                            }
                        }
                    }
                } header: {
                    ContextSectionHeader(
                        title: "Any dietary requirements?",
                        detail: "These are strict exclusions for unsuitable recipes."
                    )
                }

                Section {
                    Toggle(
                        "Prioritise ingredients expiring soon",
                        isOn: $prioritisesExpiringIngredients
                    )
                    Text("Practical recipes using urgent pantry ingredients may be ranked higher.")
                        .font(.caption)
                        .foregroundStyle(FridgeFixTheme.secondaryText)
                } header: {
                    ContextSectionHeader(
                        title: "Expiry priority",
                        detail: "Use what needs attention first."
                    )
                }

                Section {
                    NavigationLink {
                        RecommendationsView(
                            context: makeCookingContext(),
                            recommendationsViewModel:
                                recommendationsViewModel
                        )
                    } label: {
                        Label(
                            "Find realistic meals",
                            systemImage: "fork.knife.circle.fill"
                        )
                        .fridgeFixPrimaryActionTitle()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .listRowBackground(FridgeFixTheme.cardBackground)
            }
            .navigationTitle("Cooking Situation")
            .scrollContentBackground(.hidden)
            .background(FridgeFixTheme.pageBackground)
    }

    private func makeCookingContext() -> CookingContext {
        CookingContext(
            maximumCookingTime: maximumCookingTime,
            maximumDifficulty: maximumDifficulty,
            preferredCuisines: preferredCuisines,
            preferredTastes: preferredTastes,
            dietaryRestrictions: dietaryRestrictions,
            prioritisesExpiringIngredients: prioritisesExpiringIngredients
        )
    }

    private func toggle<Value: Hashable>(
        _ value: Value,
        in collection: inout Set<Value>
    ) {
        if collection.contains(value) {
            collection.remove(value)
        } else {
            collection.insert(value)
        }
    }
}

/// Presents a section heading with a short domain explanation.
private struct ContextSectionHeader: View {

    let title: String
    let detail: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .fridgeFixSectionTitle()
                .foregroundStyle(.primary)

            Text(detail)
                .font(.caption)
                .foregroundStyle(FridgeFixTheme.secondaryText)
                .textCase(nil)
        }
        .textCase(nil)
    }
}

/// Displays one optional cooking preference with an accessible selected state.
private struct SelectablePreferenceChip: View {

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(
                    systemName: isSelected
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .imageScale(.small)

                Text(title)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(
                isSelected
                    ? FridgeFixTheme.brandAccent.opacity(0.14)
                    : FridgeFixTheme.cardBackground
            )
            .clipShape(RoundedRectangle(cornerRadius: FridgeFixTheme.compactCornerRadius))
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? FridgeFixTheme.brandAccent : .primary)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

#Preview {
    CookingContextView(
        recommendationsViewModel: RecommendationsViewModel()
    )
}
