//
//  FridgeFixTheme.swift
//  FridgeFix
//
//  Created by Codex on 8/9/2026.
//

import SwiftUI
import UIKit

/// Frontend-only semantic colours for the FridgeFix interface.
enum FridgeFixTheme {

    static let pageBackground = Color(
        UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return .systemGroupedBackground
            }

            return UIColor(red: 0.98, green: 0.95, blue: 0.88, alpha: 1)
        }
    )

    static let cardBackground = Color(
        UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return .secondarySystemGroupedBackground
            }

            return UIColor(red: 1.0, green: 0.99, blue: 0.95, alpha: 1)
        }
    )

    static let primaryAccent = Color(
        UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.56, green: 0.78, blue: 0.46, alpha: 1)
            }

            return UIColor(red: 0.18, green: 0.42, blue: 0.23, alpha: 1)
        }
    )

    static let secondaryAccent = Color(
        UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.96, green: 0.78, blue: 0.27, alpha: 1)
            }

            return UIColor(red: 0.95, green: 0.70, blue: 0.18, alpha: 1)
        }
    )

    static let urgentAccent = Color.orange
    static let secondaryText = Color.secondary
}
