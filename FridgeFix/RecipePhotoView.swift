//
//  RecipePhotoView.swift
//  FridgeFix
//
//  Created by Codex on 8/9/2026.
//

import SwiftUI

/// Displays a local recipe photo with a purposeful fallback for recipes without artwork.
struct RecipePhotoView: View {

    let recipe: Recipe
    let height: CGFloat
    let cornerRadius: CGFloat

    init(
        recipe: Recipe,
        height: CGFloat,
        cornerRadius: CGFloat = 12
    ) {
        self.recipe = recipe
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        photoContent
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var photoContent: some View {
        if let photoName = recipe.localPhotoName {
            Image(photoName)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipped()
        } else {
            ZStack {
                FridgeFixTheme.cardBackground

                VStack(spacing: 8) {
                    Image(systemName: "fork.knife")
                        .font(.title2)
                        .foregroundStyle(FridgeFixTheme.secondaryText)

                    Text(recipe.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(FridgeFixTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal)
                }
            }
        }
    }

    private var accessibilityLabel: String {
        if recipe.localPhotoName != nil {
            return "Photo of \(recipe.name)"
        }

        return "No photo available for \(recipe.name)"
    }
}
