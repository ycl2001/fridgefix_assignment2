//
//  ApplySessionRecipeFeedbackUseCaseTests.swift
//  FridgeFixTests
//
//  Created by Yen-Chun Liu on 4/9/2026.
//

import Testing
@testable import FridgeFix

struct ApplySessionRecipeFeedbackUseCaseTests {

    private let useCase = ApplySessionRecipeFeedbackUseCase()

    @Test
    func savedRecipeIsRecordedInCurrentSession() throws {
        var session = RecommendationSession()

        let recipeID = RecipeID(
            rawValue: "chicken-spinach-rice-bowl"
        )

        let feedback = SessionRecipeFeedback(
            recipeID: recipeID,
            action: .saved
        )

        try useCase.execute(
            feedback: feedback,
            in: &session
        )

        #expect(
            session.feedback(for: recipeID) == .saved
        )
    }

    @Test
    func feedbackCannotBeRecordedAfterSessionEnds() {
        var session = RecommendationSession()
        session.end()

        let feedback = SessionRecipeFeedback(
            recipeID: RecipeID(
                rawValue: "chicken-spinach-rice-bowl"
            ),
            action: .skipped
        )

        #expect(
            throws: SessionRecipeFeedbackError.self
        ) {
            try useCase.execute(
                feedback: feedback,
                in: &session
            )
        }
    }
}
