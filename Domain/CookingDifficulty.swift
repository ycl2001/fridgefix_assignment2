//
//  CookingDifficulty.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.

import Foundation

/// Describes how demanding a recipe is for a home cook.
///
/// FridgeFix excludes recipes above the difficulty selected by the user.
enum CookingDifficulty: Int, CaseIterable, Codable, Comparable, Hashable {
    case easy = 1
    case moderate = 2
    case challenging = 3

    var displayName: String {
        switch self {
        case .easy:
            return "Easy"
        case .moderate:
            return "Moderate"
        case .challenging:
            return "Challenging"
        }
    }

    static func < (
        leftDifficulty: CookingDifficulty,
        rightDifficulty: CookingDifficulty
    ) -> Bool {
        leftDifficulty.rawValue < rightDifficulty.rawValue
    }
}
