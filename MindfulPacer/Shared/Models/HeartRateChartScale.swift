import Foundation

enum HeartRateChartScale {
    /// Reminder lines may extend the top, but never move the baseline away from the data.
    static func domain(values: [Double], thresholds: [Double] = []) -> ClosedRange<Double> {
        let values = values.filter { $0.isFinite && $0 > 0 }
        let minimum = values.min() ?? 60
        let maximum = max(values.max() ?? 100, thresholds.filter(\.isFinite).max() ?? 0)
        let lower = max(0, minimum - 10)
        let upperPadding = max(1, (maximum - minimum) * 0.12)
        return lower...max(lower + 1, maximum + upperPadding)
    }
}
