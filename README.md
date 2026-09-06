# FridgeFix

FridgeFix is a SwiftUI MVP that recommends meals from a user's current pantry and cooking context. It uses local sample data to demonstrate the product workflow without networking, authentication, or persistent storage.

## Problem Context

Home cooks often have ingredients available but need help choosing realistic meals before food expires. FridgeFix focuses on what can be cooked now, what should be used soon, and how much extra shopping is required.

## MVP Scope

- Show a read-only pantry overview from local sample data.
- Highlight ingredients expiring today or within the next two days.
- Capture cooking time, difficulty, cuisine, taste, dietary, and expiry preferences.
- Evaluate recipe suitability against pantry and cooking constraints.
- Generate explainable, ranked recipe recommendations.
- Group recommendations by readiness.
- Show recipe details, missing ingredients, substitutions, nutrition balance, and instructions.
- Record save, skip, and predefined feedback actions for the current session only.

## Architecture

The app follows a compact SwiftUI MVVM structure with explicit use cases and repository protocols:

```text
SwiftUI Views
  -> ViewModels
      -> Use Cases
          -> Repository Protocols
              -> Local Repositories
```

Important flows:

- `ContentView` opens `PantryView`.
- `PantryViewModel` loads ingredients through `PantryRepository`.
- `CookingContextView` builds a `CookingContext` from local form state.
- `RecommendationsViewModel` calls `GenerateContextAwareRecommendationsUseCase`.
- `GenerateContextAwareRecommendationsUseCase` loads pantry and recipe data, evaluates suitability, and ranks results.
- `RecipeDetailView` displays recipe information and records session feedback through `ApplySessionRecipeFeedbackUseCase`.

## Directory Structure

```text
Domain/          Core models and recommendation value types
Repositories/    Repository protocols
Data/            Local pantry and recipe sample data
UseCases/        Suitability, recommendation, and feedback business rules
ViewModel/       SwiftUI view models
FridgeFix/       SwiftUI app entry point and screens
FridgeFixTests/  Unit tests for domain, use cases, and repositories
FridgeFixUITests/ Generated scaffold UI tests
```

## Setup

1. Open `FridgeFix.xcodeproj` in Xcode.
2. Select the `FridgeFix` scheme.
3. Choose an iOS simulator or device supported by the installed SDK.
4. Build and run.

The project uses only Apple frameworks provided by Xcode.

## Testing

Run the unit tests from Xcode with the `FridgeFix` scheme, or use the test navigator to run `FridgeFixTests`.

The main unit coverage includes:

- Recipe suitability rules
- Recommendation generation and ranking
- Session feedback recording
- Local pantry and recipe repositories

## Known Limitations

- Pantry data is read-only and stored in local sample repositories.
- There is no durable persistence for pantry items, recipes, or feedback.
- Session feedback is held only by the active recipe detail view.
- Feedback is recorded but does not yet affect later recommendation ranking.
- UI tests are still scaffold-level tests.
- The Xcode project deployment target may require a recent Xcode/iOS SDK.
