import Foundation

enum HeartRateChartScale {
    /// Reminder lines may extend the top, but never move the baseline away from the data.
    /// Charts that must always show their reminder line opt in with `includesLowThresholds`.
    static func domain(
        values: [Double],
        thresholds: [Double] = [],
        includesLowThresholds: Bool = false
    ) -> ClosedRange<Double> {
        let values = values.filter { $0.isFinite && $0 > 0 }
        let thresholds = thresholds.filter(\.isFinite)
        var minimum = values.min() ?? 60
        let maximum = max(values.max() ?? 100, thresholds.max() ?? 0)
        if includesLowThresholds, let lowestThreshold = thresholds.min() {
            minimum = min(minimum, lowestThreshold)
        }
        let lower = max(0, minimum - 10)
        let upperPadding = max(1, (maximum - minimum) * 0.12)
        return lower...max(lower + 1, maximum + upperPadding)
    }
}
