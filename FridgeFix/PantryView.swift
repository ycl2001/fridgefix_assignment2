//
//  PantryView.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import SwiftUI

/// Displays the ingredients currently available in the user's pantry.
struct PantryView: View {

    @ObservedObject var viewModel: PantryViewModel
    @ObservedObject var recommendationsViewModel: RecommendationsViewModel

    init(
        viewModel: PantryViewModel,
        recommendationsViewModel: RecommendationsViewModel
    ) {
        self.viewModel = viewModel
        self.recommendationsViewModel = recommendationsViewModel
    }

    var body: some View {
        NavigationStack {
            pantryContent
                .navigationTitle("My Pantry")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.resetAddIngredientForm()
                            viewModel.isShowingAddIngredient = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Add ingredient")
                    }

                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            viewModel.loadPantry()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .accessibilityLabel("Refresh pantry")
                    }
                }
                .task {
                    viewModel.loadPantry()
                }
                .sheet(isPresented: $viewModel.isShowingAddIngredient) {
                    AddIngredientView(viewModel: viewModel)
                }
                .sheet(
                    item: $viewModel.ingredientBeingEditedForExpiry
                ) { ingredient in
                    EditExpiryDateView(
                        ingredient: ingredient,
                        viewModel: viewModel
                    )
                }
                .background(FridgeFixTheme.pageBackground)
        }
    }

    private var pantryContent: some View {
        List {
            introSection

            if let errorMessage = viewModel.errorMessage {
                pantryHelpSection(errorMessage: errorMessage)
            }

            if viewModel.ingredients.isEmpty {
                emptyPantrySection
            } else {
                searchAndFilterSection
                useSoonSection
                visiblePantrySection
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(FridgeFixTheme.pageBackground)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 16)
        }
    }

    private var introSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                Text("See what you can realistically cook with the ingredients you already have.")
                    .font(.subheadline)
                    .foregroundStyle(FridgeFixTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                NavigationLink {
                    CookingContextView(
                        recommendationsViewModel: recommendationsViewModel
                    )
                } label: {
                    Label("What can I cook?", systemImage: "sparkles")
                        .fridgeFixPrimaryActionTitle()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.hasPantryIngredients)

                if !viewModel.hasPantryIngredients {
                    Label(
                        "Add at least one ingredient before FridgeFix can recommend realistic meals.",
                        systemImage: "info.circle"
                    )
                    .font(.caption)
                    .foregroundStyle(FridgeFixTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(FridgeFixTheme.cardBackground)
    }

    private func pantryHelpSection(errorMessage: String) -> some View {
        Section("Pantry Help") {
            Label {
                Text(errorMessage)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }

            Button {
                viewModel.loadPantry()
            } label: {
                Label("Refresh pantry", systemImage: "arrow.clockwise")
            }
        }
        .listRowBackground(FridgeFixTheme.cardBackground)
    }

    private var emptyPantrySection: some View {
        Section {
            ContentUnavailableView {
                Label("Your Pantry Is Empty", systemImage: "refrigerator")
            } description: {
                Text("Add a few pantry ingredients before FridgeFix can recommend realistic meals.")
            } actions: {
                Button {
                    viewModel.resetAddIngredientForm()
                    viewModel.isShowingAddIngredient = true
                } label: {
                    Label("Add ingredient", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .listRowBackground(FridgeFixTheme.cardBackground)
    }

    private var searchAndFilterSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                PantrySearchField(searchText: $viewModel.searchText)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        PantryCategoryFilterChip(
                            title: "All",
                            isSelected: viewModel.selectedCategory == nil
                        ) {
                            viewModel.selectedCategory = nil
                        }

                        ForEach(
                            viewModel.availableCategoryFilters,
                            id: \.self
                        ) { category in
                            PantryCategoryFilterChip(
                                title: category.displayName,
                                isSelected: viewModel.selectedCategory == category
                            ) {
                                viewModel.selectedCategory = category
                            }
                        }
                    }
                    .padding(.trailing, 4)
                }
            }
            .padding(.vertical, 4)
        }
        .listRowInsets(
            EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        )
        .listRowBackground(FridgeFixTheme.cardBackground)
    }

    private var useSoonSection: some View {
        Section {
            if viewModel.visibleIngredientsExpiringSoon.isEmpty {
                Label(
                    viewModel.hasActiveFilters
                        ? "No urgent ingredients match these filters."
                        : "No ingredients need urgent attention today.",
                    systemImage: "checkmark.circle"
                )
                .font(.subheadline)
                .foregroundStyle(FridgeFixTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(
                            viewModel.visibleIngredientsExpiringSoon
                        ) { ingredient in
                            UseSoonIngredientCard(
                                ingredient: ingredient,
                                editExpiryDate: {
                                    viewModel.beginEditingExpiryDate(
                                        for: ingredient
                                    )
                                }
                            )
                        }
                    }
                    .padding(.trailing, 4)
                }
            }
        } header: {
            Label("Use Soon", systemImage: "clock.badge.exclamationmark")
        } footer: {
            Text("Ingredients expiring today or within two days are highlighted so you can use them first.")
        }
        .listRowInsets(
            EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
        )
        .listRowBackground(FridgeFixTheme.cardBackground)
    }

    private var visiblePantrySection: some View {
        Section {
            if viewModel.isShowingFilteredEmptyState {
                filteredEmptyState
            } else {
                ForEach(viewModel.visibleIngredients) { ingredient in
                    PantryIngredientRow(
                        ingredient: ingredient,
                        isUrgent: ingredient.isExpiringSoon,
                        editExpiryDate: {
                            viewModel.beginEditingExpiryDate(for: ingredient)
                        }
                    )
                }
                .onDelete { offsets in
                    viewModel.removePantryIngredients(
                        offsets.map {
                            viewModel.visibleIngredients[$0]
                        }
                    )
                }
            }
        } header: {
            Text("My Pantry")
        } footer: {
            if !viewModel.visibleIngredientsExpiringSoon.isEmpty {
                Text("Urgent ingredients also appear here so pantry editing and deletion stay in one complete list.")
            }
        }
        .listRowBackground(FridgeFixTheme.cardBackground)
    }

    private var filteredEmptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            ContentUnavailableView {
                Label("No pantry matches", systemImage: "magnifyingglass")
            } description: {
                Text("Try another search, choose All, or add the ingredient you expected to find.")
            }

            HStack(spacing: 12) {
                Button {
                    viewModel.clearFilters()
                } label: {
                    Label("Clear filters", systemImage: "xmark.circle")
                }
                .buttonStyle(.bordered)

                Button {
                    viewModel.resetAddIngredientForm()
                    viewModel.isShowingAddIngredient = true
                } label: {
                    Label("Add ingredient", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 8)
    }
}

/// Displays a compact pantry search field for existing pantry ingredients.
private struct PantrySearchField: View {

    @Binding var searchText: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(FridgeFixTheme.secondaryText)
                .accessibilityHidden(true)

            TextField("Search your pantry", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(FridgeFixTheme.secondaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear pantry search")
            }
        }
        .padding(.horizontal, 12)
        .frame(minHeight: FridgeFixTheme.compactActionHeight)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(
            RoundedRectangle(cornerRadius: FridgeFixTheme.compactCornerRadius)
        )
        .accessibilityElement(children: .contain)
    }
}

/// Selects one pantry category filter.
private struct PantryCategoryFilterChip: View {

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontDesign(.rounded)
                .fontWeight(.semibold)
                .foregroundStyle(isSelected ? .white : FridgeFixTheme.primaryText)
                .padding(.horizontal, 14)
                .frame(minHeight: 36)
        }
        .buttonStyle(.plain)
        .background(
            isSelected
                ? FridgeFixTheme.brandAccent
                : Color(.secondarySystemGroupedBackground)
        )
        .clipShape(Capsule())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Highlights one urgent ingredient in the horizontal Use Soon section.
private struct UseSoonIngredientCard: View {

    let ingredient: PantryIngredient
    let editExpiryDate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(ingredient.name)
                        .fridgeFixCardTitle()
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(ingredient.substitutionCategory.displayName)
                        .font(.caption)
                        .foregroundStyle(FridgeFixTheme.secondaryText)
                }
            }

            Text(expiryText)
                .font(.caption)
                .foregroundStyle(.orange)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                editExpiryDate()
            } label: {
                Label("Edit expiry", systemImage: "pencil.circle")
                    .font(.caption)
                    .fontDesign(.rounded)
                    .fontWeight(.semibold)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("Edit \(ingredient.name) expiry date")
            .accessibilityHint("Changes the stored expiry date for this pantry ingredient.")
        }
        .frame(width: 168, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(
            RoundedRectangle(cornerRadius: FridgeFixTheme.compactCornerRadius)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(ingredient.name), \(ingredient.substitutionCategory.displayName), \(expiryText)"
        )
    }

    private var expiryText: String {
        guard let expiresAt = ingredient.expiresAt else {
            return "Expiry date unknown"
        }

        return "Expires \(expiresAt.formatted(date: .abbreviated, time: .omitted))"
    }
}

/// Displays one pantry ingredient and its expiry status.
private struct PantryIngredientRow: View {

    let ingredient: PantryIngredient
    let isUrgent: Bool
    let editExpiryDate: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(
                systemName: isUrgent
                    ? "exclamationmark.triangle.fill"
                    : "leaf.fill"
            )
            .foregroundStyle(isUrgent ? .orange : .green)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name)
                    .fridgeFixCardTitle()
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(ingredient.substitutionCategory.displayName)
                    .font(.caption)
                    .foregroundStyle(FridgeFixTheme.secondaryText)

                if let expiresAt = ingredient.expiresAt {
                    Text("Expires \(expiresAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(
                            isUrgent ? .orange : FridgeFixTheme.secondaryText
                        )
                }
            }

            Spacer(minLength: 8)

            Button {
                editExpiryDate()
            } label: {
                Image(systemName: "pencil.circle")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(expiryActionAccessibilityLabel)
            .accessibilityHint("Changes the stored expiry date for this pantry ingredient.")
        }
        .padding(.vertical, 4)
    }

    private var expiryActionAccessibilityLabel: String {
        if ingredient.expiresAt == nil {
            return "Add expiry date for \(ingredient.name)"
        }

        return "Edit \(ingredient.name) expiry date"
    }
}

/// Collects a new pantry ingredient from the user.
private struct AddIngredientView: View {

    @ObservedObject var viewModel: PantryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Ingredient") {
                    TextField(
                        "Name",
                        text: $viewModel.newIngredientName
                    )

                    Picker(
                        "Substitution Category",
                        selection: $viewModel.newIngredientCategory
                    ) {
                        ForEach(
                            IngredientSubstitutionCategory.allCases,
                            id: \.self
                        ) { category in
                            Text(category.displayName)
                                .tag(category)
                        }
                    }
                }

                Section("Expiry") {
                    Toggle(
                        "Has expiry date",
                        isOn: $viewModel.newIngredientHasExpiryDate
                    )

                    if viewModel.newIngredientHasExpiryDate {
                        DatePicker(
                            "Expiry Date",
                            selection: $viewModel.newIngredientExpiryDate,
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationTitle("Add Ingredient")
            .scrollContentBackground(.hidden)
            .background(FridgeFixTheme.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.resetAddIngredientForm()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addPantryIngredient()
                    }
                }
            }
        }
    }
}

/// Updates or clears the expiry date for an existing pantry ingredient.
private struct EditExpiryDateView: View {

    let ingredient: PantryIngredient
    @ObservedObject var viewModel: PantryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Ingredient") {
                    Text(ingredient.name)
                    Text(ingredient.substitutionCategory.displayName)
                        .foregroundStyle(FridgeFixTheme.secondaryText)
                }

                Section("Expiry") {
                    Toggle(
                        "Has expiry date",
                        isOn: $viewModel.editedIngredientHasExpiryDate
                    )

                    if viewModel.editedIngredientHasExpiryDate {
                        DatePicker(
                            "Expiry Date",
                            selection: $viewModel.editedIngredientExpiryDate,
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationTitle("Edit Expiry")
            .scrollContentBackground(.hidden)
            .background(FridgeFixTheme.pageBackground)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelEditingExpiryDate()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.saveEditedExpiryDate()
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PantryView(
        viewModel: PantryViewModel(),
        recommendationsViewModel: RecommendationsViewModel()
    )
}
