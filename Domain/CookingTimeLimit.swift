//
//  CookingTimeLimit.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation

/// Represents the maximum total time a user has available to prepare and cook a meal.
///
/// FridgeFix excludes recipes whose preparation and cooking time exceeds this limit.
enum CookingTimeLimit: Int, CaseIterable, Codable, Hashable {
    case fifteenMinutes = 15
    case thirtyMinutes = 30
    case fortyFiveMinutes = 45
    case sixtyMinutes = 60

    var displayName: String {
        "Up to \(rawValue) minutes"
    }
}
