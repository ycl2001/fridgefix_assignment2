//
//  ContentView.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import SwiftUI

struct ContentView: View {

    @StateObject private var pantryViewModel = PantryViewModel()
    @StateObject private var recommendationsViewModel =
        RecommendationsViewModel()
    @State private var selectedTab: FridgeFixTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            PantryView(
                viewModel: pantryViewModel,
                recommendationsViewModel: recommendationsViewModel
            )
            .tabItem {
                Label("Pantry", systemImage: "cabinet.fill")
            }
            .tag(FridgeFixTab.pantry)

            HomeView(
                pantryViewModel: pantryViewModel,
                recommendationsViewModel: recommendationsViewModel,
                selectedTab: $selectedTab
            )
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(FridgeFixTab.home)

            RecipesTabView(
                recommendationsViewModel: recommendationsViewModel
            )
            .tabItem {
                Label("Recipes", systemImage: "fork.knife")
            }
            .tag(FridgeFixTab.recipes)
        }
        .tint(FridgeFixTheme.brandAccent)
    }
}

enum FridgeFixTab: Hashable {
    case pantry
    case home
    case recipes
}

private struct RecipesTabView: View {

    @ObservedObject var recommendationsViewModel: RecommendationsViewModel

    var body: some View {
        NavigationStack {
            if recommendationsViewModel.hasRecommendations ||
                recommendationsViewModel.isLoading ||
                recommendationsViewModel.errorMessage != nil {
                RecommendationsView(
                    recommendationsViewModel: recommendationsViewModel
                )
            } else {
                recipesEmptyState
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
        .scrollContentBackground(.hidden)
        .background(FridgeFixTheme.pageBackground)
    }

    private var recipesEmptyState: some View {
        ZStack {
            FridgeFixTheme.pageBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: FridgeFixTheme.sectionSpacing) {
                    Text("Recipes")
                        .fridgeFixScreenTitle()
                        .padding(.top, 12)

                    VStack(alignment: .leading, spacing: 16) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 52))
                            .foregroundStyle(FridgeFixTheme.brandAccent)
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("No meal options yet")
                                .fridgeFixSectionTitle()

                            Text("Set your cooking context to find realistic meals from your pantry.")
                                .font(.subheadline)
                                .foregroundStyle(FridgeFixTheme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        NavigationLink {
                            CookingContextView(
                                recommendationsViewModel:
                                    recommendationsViewModel
                            )
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "sparkles")
                                    .accessibilityHidden(true)

                                Text("What can I cook?")
                                    .fridgeFixPrimaryActionTitle()
                                    .foregroundStyle(.white)

                                Spacer(minLength: 8)

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .accessibilityHidden(true)
                            }
                            .padding(.horizontal, 16)
                            .frame(minHeight: 54)
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(.white)
                            .background(FridgeFixTheme.brandAccent)
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius:
                                        FridgeFixTheme.compactCornerRadius,
                                    style: .continuous
                                )
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("What can I cook?")
                        .accessibilityHint(
                            "Opens the cooking context flow for meal recommendations."
                        )
                    }
                    .padding(FridgeFixTheme.cardPadding)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(FridgeFixTheme.cardBackground)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: FridgeFixTheme.cardCornerRadius,
                            style: .continuous
                        )
                    )
                }
                .padding(FridgeFixTheme.screenPadding)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 24)
            }
        }
    }
}

#Preview {
    ContentView()
}
