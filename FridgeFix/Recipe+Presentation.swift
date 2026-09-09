//
//  Recipe+Presentation.swift
//  FridgeFix
//
//  Created by Yen-Chun Liu on 8/9/2026.
//

import Foundation

/// Presentation-only helpers for local recipe imagery.
extension Recipe {

    /// The asset-catalog image set that visually represents this recipe, when available.
    var localPhotoName: String? {
        switch id.rawValue {
        case "chicken-spinach-rice-bowl":
            return "chicken_spinach_rice"
        case "vegetable-pasta":
            return "tomato_pasta"
        case "tofu-fried-rice":
            return "tofu_stir_fry"
        default:
            return nil
        }
    }
}
