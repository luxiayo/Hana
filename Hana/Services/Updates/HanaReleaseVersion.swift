import Foundation

struct HanaReleaseVersion: Comparable, Hashable, Sendable {
    let components: [Int]
    let displayText: String

    var prefixedDisplayText: String {
        displayText.lowercased().hasPrefix("v") ? displayText : "v\(displayText)"
    }

    init?(_ rawValue: String) {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        var text = trimmed
        if text.lowercased().hasPrefix("v") {
            text.removeFirst()
        }

        let versionPrefix = text.prefix { character in
            character.isNumber || character == "."
        }
        let components = versionPrefix
            .split(separator: ".", omittingEmptySubsequences: false)
            .compactMap { Int($0) }

        guard !components.isEmpty else { return nil }
        self.components = components
        self.displayText = trimmed
    }

    static func < (lhs: HanaReleaseVersion, rhs: HanaReleaseVersion) -> Bool {
        let count = max(lhs.components.count, rhs.components.count)
        for index in 0..<count {
            let lhsValue = index < lhs.components.count ? lhs.components[index] : 0
            let rhsValue = index < rhs.components.count ? rhs.components[index] : 0
            if lhsValue != rhsValue {
                return lhsValue < rhsValue
            }
        }
        return false
    }
}
