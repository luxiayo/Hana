import AVKit
import Foundation

enum HanaPlaybackSpeedCatalog {
    static var longPressRates: [Double] {
        [1.5, 2.0, 2.5, 3.0]
    }

    static var defaultLongPressRate: Double {
        normalizedLongPressRate(2)
    }

    static func normalizedLongPressRate(_ value: Double) -> Double {
        let rates = longPressRates
        precondition(!rates.isEmpty, "Long press rates must not be empty.")
        return rates.min { abs($0 - value) < abs($1 - value) }!
    }

    static func title(for rate: Double) -> String {
        if rate.rounded(.towardZero) == rate {
            return "\(Int(rate))x"
        }
        return "\(rate.formatted(.number.precision(.fractionLength(0...2))))x"
    }
}
