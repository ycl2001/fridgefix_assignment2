//
//  CookingContentView.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import SwiftUI

/// Collects the user's current cooking limits and meal preferences.
struct CookingContextView: View {

    @State private var maximumCookingTime: CookingTimeLimit = .thirtyMinutes
    @State private var maximumDifficulty: CookingDifficulty = .moderate
    @State private var preferredCuisines: Set<Cuisine> = [.asian]
    @State private var preferredTastes: Set<TastePreference> = [.savoury]
    @State private var dietaryRestrictions: Set<DietaryRestriction> = []
    @State private var prioritisesExpiringIngredients = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Cooking Limits") {
                    Picker("Available Time", selection: $maximumCookingTime) {
                        ForEach(CookingTimeLimit.allCases, id: \.self) { timeLimit in
                            Text(timeLimit.displayName)
                                .tag(timeLimit)
                        }
                    }

                    Picker("Maximum Difficulty", selection: $maximumDifficulty) {
                        ForEach(CookingDifficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.displayName)
                                .tag(difficulty)
                        }
                    }
                }

                Section("Cuisine Preferences") {
                    ForEach(Cuisine.allCases, id: \.self) { cuisine in
                        preferenceToggle(
                            title: cuisine.rawValue.capitalized,
                            isSelected: preferredCuisines.contains(cuisine)
                        ) {
                            toggle(cuisine, in: &preferredCuisines)
                        }
                    }
                }

                Section("Taste Preferences") {
                    ForEach(TastePreference.allCases, id: \.self) { taste in
                        preferenceToggle(
                            title: taste.rawValue.capitalized,
                            isSelected: preferredTastes.contains(taste)
                        ) {
                            toggle(taste, in: &preferredTastes)
                        }
                    }
                }

                Section("Dietary Restrictions") {
                    ForEach(DietaryRestriction.allCases, id: \.self) { restriction in
                        preferenceToggle(
                            title: restriction.rawValue
                                .replacingOccurrences(
                                    of: "Free",
                                    with: " Free"
                                )
                                .capitalized,
                            isSelected: dietaryRestrictions.contains(restriction)
                        ) {
                            toggle(restriction, in: &dietaryRestrictions)
                        }
                    }
                }

                Section("Expiry Preference") {
                    Toggle(
                        "Prioritise ingredients expiring soon",
                        isOn: $prioritisesExpiringIngredients
                    )
                }

                Section {
                    NavigationLink {
                        RecommendationsView(
                            context: makeCookingContext()
                        )
                    } label: {
                        Text("Find Meals I Can Cook")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Cooking Context")
        }
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

    private func preferenceToggle(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)

                Spacer()

                Image(
                    systemName: isSelected
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .foregroundStyle(
                    isSelected ? .purple : .secondary
                )
            }
        }
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

#Preview {
    CookingContextView()
}
