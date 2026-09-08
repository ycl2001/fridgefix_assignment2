//
//  IngredientArtworkView.swift
//  FridgeFix
//
//  Created by Codex on 8/9/2026.
//

import SwiftUI

/// Displays local ingredient or category artwork with a consistent fallback.
struct IngredientArtworkView: View {

    let kind: IngredientArtworkKind
    let size: CGSize
    let cornerRadius: CGFloat
    let isCircular: Bool

    init(
        kind: IngredientArtworkKind,
        size: CGSize,
        cornerRadius: CGFloat = FridgeFixTheme.compactCornerRadius,
        isCircular: Bool = false
    ) {
        self.kind = kind
        self.size = size
        self.cornerRadius = cornerRadius
        self.isCircular = isCircular
    }

    var body: some View {
        Group {
            if let assetName = kind.assetName {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    FridgeFixTheme.cardBackground
                    Image(systemName: kind.fallbackSystemImage)
                        .font(.headline)
                        .foregroundStyle(FridgeFixTheme.brandAccent)
                }
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(shape)
        .contentShape(shape)
    }

    private var shape: AnyShape {
        if isCircular {
            return AnyShape(Circle())
        }

        return AnyShape(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
    }
}

enum IngredientArtworkKind {
    case ingredient(name: String, category: IngredientSubstitutionCategory)
    case category(IngredientSubstitutionCategory?)

    fileprivate var assetName: String? {
        switch self {
        case .ingredient(let name, _):
            return Self.ingredientAssetNames[name.normalizedIngredientName]
        case .category(let category):
            guard let category else {
                return nil
            }

            return Self.categoryAssetNames[category]
        }
    }

    fileprivate var fallbackSystemImage: String {
        switch self {
        case .ingredient(_, let category):
            return category.fallbackSystemImage
        case .category(let category):
            return category?.fallbackSystemImage ?? "square.grid.2x2"
        }
    }

    private static let ingredientAssetNames: [String: String] = [
        "chicken": "ingredient_chicken",
        "garlic": "ingredient_garlic",
        "rice": "ingredient_rice",
        "spinach": "ingredient_spinach",
        "tofu": "ingredient_tofu",
        "tomato": "ingredient_tomato"
    ]

    private static let categoryAssetNames: [IngredientSubstitutionCategory: String] = [
        .aromatic: "category_aromatics",
        .grain: "category_pasta",
        .leafyGreen: "category_vegetables",
        .protein: "category_protein"
    ]
}

private extension String {

    var normalizedIngredientName: String {
        lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension IngredientSubstitutionCategory {

    var fallbackSystemImage: String {
        switch self {
        case .leafyGreen:
            return "leaf.fill"
        case .aromatic:
            return "flame.fill"
        case .protein:
            return "fork.knife"
        case .grain:
            return "takeoutbag.and.cup.and.straw.fill"
        case .cookingOil:
            return "drop.fill"
        }
    }
}
