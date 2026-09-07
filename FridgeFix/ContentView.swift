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
                ContentUnavailableView {
                    Label("No meal options yet", systemImage: "fork.knife")
                } description: {
                    Text("Set your cooking context to find realistic meals from your pantry.")
                } actions: {
                    NavigationLink {
                        CookingContextView(
                            recommendationsViewModel:
                                recommendationsViewModel
                        )
                    } label: {
                        Label(
                            "Set my cooking context",
                            systemImage: "slider.horizontal.3"
                        )
                    }
                    .buttonStyle(.borderedProminent)
                }
                .navigationTitle("Recipes")
            }
        }
    }
}

#Preview {
    ContentView()
}
