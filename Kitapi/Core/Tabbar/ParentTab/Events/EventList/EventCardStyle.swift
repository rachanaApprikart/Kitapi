import UIKit

enum EventCardStyle {
    /// Stable category colors, derived exclusively from the existing app palette.
    static func categoryTint(_ category: String?) -> UIColor {
        let colors: [UIColor] = [.pinkPrimaryColor, .greenPrimaryColor, .bluePrimaryColor, .yellowPrimaryColor, .redPrimaryColor, .purplePrimaryColor]
        let name = category?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        guard !name.isEmpty else { return .gradientColor1 }
        let index = name.utf8.reduce(0) { ($0 + Int($1)) % colors.count }
        return colors[index].withAlphaComponent(0.12)
    }
}
