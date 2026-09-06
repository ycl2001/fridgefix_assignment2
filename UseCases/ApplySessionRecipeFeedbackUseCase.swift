//
//  ApplySessionRecipeFeedbackUseCase.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation

/// Records a user's save, skip, or predefined feedback action.
///
/// Feedback affects recommendation ordering only during the current session.
/// It never overrides dietary restrictions, time limits, or difficulty limits.
struct ApplySessionRecipeFeedbackUseCase {

    /// Applies feedback to the active recommendation session.
    ///
    /// - Parameters:
    ///   - feedback: The user's action on a recipe.
    ///   - session: The current recommendation session.
    /// - Throws: `SessionRecipeFeedbackError` if the session has ended.
    func execute(
        feedback: SessionRecipeFeedback,
        in session: inout RecommendationSession
    ) throws {
        guard session.isActive else {
            throw SessionRecipeFeedbackError.recommendationSessionHasEnded
        }

        session.record(feedback)
    }
}

/// Describes failures when recording recommendation feedback.
enum SessionRecipeFeedbackError: Error, Equatable, LocalizedError {
    case recommendationSessionHasEnded

    var errorDescription: String? {
        switch self {
        case .recommendationSessionHasEnded:
            return "This recommendation session has ended."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .recommendationSessionHasEnded:
            return "Start a new recommendation search before saving or reporting recipes."
        }
    }
}
