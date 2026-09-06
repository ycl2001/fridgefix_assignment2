//
//  RecommendationSession.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Foundation

/// Represents one temporary recommendation session.
///
/// A session begins when the user requests meal recommendations and ends when
/// the user leaves that recommendation flow. Save, skip, and feedback actions
/// are stored only for the duration of this session.

struct RecommendationSession: Equatable {

    let id: UUID
    private(set) var isActive: Bool
    private(set) var feedbackByRecipeID: [RecipeID: SessionRecipeFeedbackAction]

    init(id: UUID = UUID()) {
        self.id = id
        self.isActive = true
        self.feedbackByRecipeID = [:]
    }

    /// Records the user's latest action for a recipe in this session.
    mutating func record(_ feedback: SessionRecipeFeedback) {
        feedbackByRecipeID[feedback.recipeID] = feedback.action
    }

    /// Returns the user's latest action for a recipe, if one exists.
    func feedback(for recipeID: RecipeID) -> SessionRecipeFeedbackAction? {
        feedbackByRecipeID[recipeID]
    }

    /// Ends the current recommendation session.
    mutating func end() {
        isActive = false
    }
}
