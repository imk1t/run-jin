import Foundation

// MARK: - FormatHelpers

/// Locale-aware formatting utilities for running stats.
/// Japan market uses km for distance. All formatters respect the user's locale
/// for number separators while keeping domain-specific formats consistent.
enum FormatHelpers {

    // MARK: - Distance

    /// Format meters as km with two decimal places (e.g. "5.23").
    /// Returns the numeric string only; callers attach the unit label.
    static func distanceKm(meters: Double) -> String {
        let km = meters / 1000.0
        return distanceFormatter.string(from: NSNumber(value: km)) ?? String(format: "%.2f", km)
    }

    /// Format meters as km with unit suffix (e.g. "5.23 km").
    static func distanceKmWithUnit(meters: Double) -> String {
        "\(distanceKm(meters: meters)) km"
    }

    // MARK: - Duration

    /// Format seconds as `M:SS` (e.g. "42:05") for durations under 1 hour,
    /// or `H:MM:SS` (e.g. "1:02:05") for longer durations.
    static func duration(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    /// Format seconds as zero-padded `MM:SS` (e.g. "02:05").
    /// Useful for live running displays where column alignment matters.
    static func durationPadded(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    // MARK: - Pace

    /// Format pace in seconds-per-km as `M:SS` (e.g. "5:30").
    /// Returns "--:--" when pace is nil or non-positive.
    static func pace(secondsPerKm: Double?) -> String {
        guard let pace = secondsPerKm, pace > 0, pace.isFinite else { return "--:--" }
        let totalSeconds = Int(pace)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Format pace with unit suffix (e.g. "5:30/km").
    static func paceWithUnit(secondsPerKm: Double?) -> String {
        "\(pace(secondsPerKm: secondsPerKm))/km"
    }

    // MARK: - Calories

    /// Format calorie count (non-optional).
    static func calories(_ value: Int) -> String {
        calorieFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// Format calorie count. Returns "--" when nil.
    static func calories(_ value: Int?) -> String {
        guard let cal = value else { return "--" }
        return calories(cal)
    }

    // MARK: - Splits

    /// Format a split label (e.g. "1 km" or "450m" for partial).
    static func splitLabel(km: Int, isPartial: Bool, partialMeters: Double) -> String {
        if isPartial {
            return String(format: "%dm", Int(partialMeters))
        }
        return "\(km) km"
    }

    // MARK: - Date

    /// Short date for run history rows (locale-aware).
    static func shortDate(_ date: Date) -> String {
        shortDateFormatter.string(from: date)
    }

    /// Time-only display (locale-aware).
    static func timeOnly(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }

    /// Navigation title date: "month day weekday" format.
    static func navigationTitleDate(_ date: Date) -> String {
        navigationDateFormatter.string(from: date)
    }

    // MARK: - Private Formatters (cached)

    private static let distanceFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    private static let calorieFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    private static let navigationDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("MMMdEEEE")
        return f
    }()
}
