//
//  FridgeFixTheme.swift
//  FridgeFix
//
//  Created by Codex on 8/9/2026.
//

import SwiftUI

/// Shared presentation values for FridgeFix screens.
enum FridgeFixTheme {

    static let pageBackground = Color("AppBackground")
    static let cardBackground = Color("CardBackground")
    static let brandAccent = Color("BrandAccent")

    static let cardCornerRadius: CGFloat = 16
    static let compactCornerRadius: CGFloat = 12
    static let screenPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 20
    static let cardPadding: CGFloat = 14
    static let compactActionHeight: CGFloat = 48
}

extension View {

    /// Applies the rounded FridgeFix title style used for screen-level headings.
    func fridgeFixScreenTitle() -> some View {
        font(.title2)
            .fontDesign(.rounded)
            .fontWeight(.bold)
    }

    /// Applies the rounded FridgeFix style used for section headings.
    func fridgeFixSectionTitle() -> some View {
        font(.headline)
            .fontDesign(.rounded)
            .fontWeight(.semibold)
    }

    /// Applies the rounded FridgeFix style used for compact card titles.
    func fridgeFixCardTitle() -> some View {
        font(.headline)
            .fontDesign(.rounded)
            .fontWeight(.semibold)
    }

    /// Applies the rounded FridgeFix style used for primary actions.
    func fridgeFixPrimaryActionTitle() -> some View {
        font(.headline)
            .fontDesign(.rounded)
            .fontWeight(.semibold)
    }
}
