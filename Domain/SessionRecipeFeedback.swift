//
//  SessionRecipeFeedback.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation

/// Represents an action a user takes on a recipe during the current session.
enum SessionRecipeFeedbackAction: Equatable {
    case saved
    case skipped
    case reported(SessionRecipeFeedbackReason)
}

/// Provides a predefined reason for rejecting a recommendation.
enum SessionRecipeFeedbackReason: String, CaseIterable, Equatable {
    case tooMuchShopping
    case takesTooLong
    case tooDifficult
    case notMyTaste

    var displayText: String {
        switch self {
        case .tooMuchShopping:
            return "Requires too much shopping"
        case .takesTooLong:
            return "Takes too long"
        case .tooDifficult:
            return "Too difficult"
        case .notMyTaste:
            return "Not my taste"
        }
    }
}

/// Records a user's response to a recipe recommendation.
///
/// Feedback only affects recommendation ranking during the current session.
/// It is not stored as a permanent user profile in the MVP.
struct SessionRecipeFeedback: Equatable {
    let recipeID: RecipeID
    let action: SessionRecipeFeedbackAction
}
