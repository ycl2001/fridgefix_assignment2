# FridgeFix

FridgeFix is a SwiftUI MVP that recommends meals from a user's current pantry and cooking context. It uses local sample data to demonstrate the product workflow without networking, authentication, or persistent storage.

## Problem Context

Home cooks often have ingredients available but need help choosing realistic meals before food expires. FridgeFix focuses on what can be cooked now, what should be used soon, and how much extra shopping is required.

## MVP Scope

- Show a searchable pantry seeded with local sample data.
- Add and remove pantry ingredients, and add, edit, or clear expiry dates.
- Highlight ingredients expiring today or within the next two days.
- Capture cooking time, difficulty, cuisine, taste, dietary, and expiry preferences.
- Evaluate recipe suitability against pantry and cooking constraints.
- Generate explainable, ranked recipe recommendations.
- Group recommendations by readiness.
- Show recipe details, missing ingredients, substitutions, nutrition balance, and instructions.
- Apply save, skip, and predefined feedback actions to recommendations in the active session.

## Screens and User Flow

- **Pantry:** search and filter ingredients, add or remove items, edit expiry information, and see ingredients that should be used soon.
- **Home:** open the cooking-context flow, review current recommendations, and find meals that use urgent ingredients.
- **Cooking Situation:** set time and difficulty limits, optional cuisine and taste preferences, dietary restrictions, and expiry priority.
- **Meal Options:** review explainable recommendations grouped as ready to cook, almost ready, or needing one or two ingredients.
- **Recipe Detail:** inspect suitability, pantry coverage, substitutions, shopping needs, nutrition, directions, and session feedback controls.
- **Recipes:** return to the active recommendation results or start the cooking-context flow when no results have been generated.

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

- `ContentView` shares pantry and recommendation view models across the Pantry, Home, and Recipes tabs.
- `PantryViewModel` loads and changes ingredients through `PantryRepository`.
- `CookingContextView` builds a `CookingContext` from local form state.
- `RecommendationsViewModel` calls `GenerateContextAwareRecommendationsUseCase`.
- `GenerateContextAwareRecommendationsUseCase` loads pantry and recipe data, evaluates suitability, and ranks results.
- `RecipeDetailView` displays recipe information and records session feedback through `ApplySessionRecipeFeedbackUseCase`.

The three main Use Cases keep domain rules out of the SwiftUI views:

- `EvaluateRecipeSuitabilityUseCase` applies hard constraints, checks pantry coverage and substitutions, and assigns readiness.
- `GenerateContextAwareRecommendationsUseCase` excludes unsuitable or incomplete recipes, builds explanations, applies active-session feedback, and sorts the remaining options.
- `ApplySessionRecipeFeedbackUseCase` records the latest save, skip, or feedback action for a recipe while the session is active.

## Recommendation and Feedback Rules

Time, maximum difficulty, and dietary restrictions are hard constraints. Cuisine and taste are ranking preferences, while expiry priority can promote a practical recipe that uses an ingredient expiring soon. Recipes that need more than two ingredients or lack an essential ingredient without an allowed substitution are excluded.

Save, skip, and feedback affect only the active `RecommendationSession`:

- Saving promotes suitable recipes with a similar cuisine or taste.
- Skipping removes that recipe from later results in the same session.
- “Requires too much shopping” lowers recipes that need one or two ingredients; “Takes too long” prefers shorter options; “Too difficult” prefers easier options and lowers recipes at or above the reported difficulty; “Not my taste” lowers recipes with matching cuisine or taste traits.
- Feedback never overrides hard cooking constraints, and an ended session no longer influences ranking.

## Domain Situations and Recovery

FridgeFix presents domain-specific messages with a practical next step instead of treating every missing result as a technical failure.

- **Operation failures:** unavailable pantry or recipe data, a duplicate pantry item, a missing item during an update, or feedback submitted after a session ends are failures. The domain errors provide an explanation and recovery suggestion; pantry and recommendation screens present the applicable retry, refresh, or correction guidance. Recipe feedback that cannot be recorded is reported as a feedback failure.
- **Normal empty states:** an empty pantry, a pantry search or category filter with no matches, and a Recipes tab with no generated meal options are valid states. The app directs the user to add ingredients, clear pantry filters, or start the cooking-context flow.
- **Recommendation exclusions:** a completed recommendation run can return no meals because hard filters exclude the catalogue, the pantry cannot support a realistic recipe, or recipe information is incomplete. These cases are reported separately with relevant actions such as relaxing filters, reviewing dietary restrictions, adding pantry ingredients, allowing limited shopping, or trying again after catalogue data is corrected.

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
- Recommendation generation, ranking, and domain-specific empty-result errors
- Session feedback recording and its active-session ranking effects
- Pantry search, category filtering, featured urgent ingredients, and add-flow behavior
- Local pantry mutations and local recipe repository behavior
- User-facing recovery guidance produced by recommendation view-model errors

## Known Limitations

- Pantry changes are held by a shared in-memory repository and reset when the app session ends.
- Recipes are a curated local catalogue; there is no network service, authentication, or durable storage.
- The pantry tracks ingredient availability and optional expiry dates, but not quantities.
- Save, skip, and feedback influence only the active recommendation session and do not create a permanent profile or saved collection.
- UI tests are still scaffold-level tests.
- The Xcode project deployment target may require a recent Xcode/iOS SDK.
