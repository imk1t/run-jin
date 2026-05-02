import Foundation

/// All custom analytics events for Run-Jin.
enum AnalyticsEvent: String, Sendable {
    // MARK: - Running

    /// User started a run session.
    case runStarted = "run_started"
    /// User completed a run session.
    case runCompleted = "run_completed"
    /// User paused a run session.
    case runPaused = "run_paused"

    // MARK: - Territory

    /// User captured a territory hex cell.
    case territoryCaptured = "territory_captured"
    /// User lost a territory hex cell to another runner.
    case territoryLost = "territory_lost"

    // MARK: - Achievements

    /// User unlocked an achievement.
    case achievementUnlocked = "achievement_unlocked"

    // MARK: - Teams

    /// User joined a team.
    case teamJoined = "team_joined"
    /// User created a team.
    case teamCreated = "team_created"

    // MARK: - Monetization

    /// User purchased a subscription.
    case subscriptionPurchased = "subscription_purchased"

    // MARK: - Sharing

    /// User generated a share image.
    case shareImageGenerated = "share_image_generated"

    // MARK: - HealthKit

    /// User requested HealthKit authorization.
    case healthKitAuthorizationRequested = "healthkit_auth_requested"
    /// User granted HealthKit authorization.
    case healthKitAuthorizationGranted = "healthkit_auth_granted"
    /// User denied HealthKit authorization.
    case healthKitAuthorizationDenied = "healthkit_auth_denied"
    /// Workout successfully saved to HealthKit.
    case healthKitWorkoutSaved = "healthkit_workout_saved"
    /// Failed to save workout to HealthKit.
    case healthKitWorkoutSaveFailed = "healthkit_workout_save_failed"
}

/// Parameter keys used with analytics events.
enum AnalyticsParameterKey: String, Sendable {
    // MARK: - Run parameters

    case runId = "run_id"
    case durationSeconds = "duration_seconds"
    case distanceMeters = "distance_meters"
    case averagePaceSecondsPerKm = "avg_pace_sec_per_km"
    case caloriesBurned = "calories_burned"

    // MARK: - Territory parameters

    case h3Index = "h3_index"
    case cellCount = "cell_count"
    case resolution = "resolution"

    // MARK: - Achievement parameters

    case achievementId = "achievement_id"
    case achievementName = "achievement_name"

    // MARK: - Team parameters

    case teamId = "team_id"
    case teamName = "team_name"
    case memberCount = "member_count"

    // MARK: - Subscription parameters

    case productId = "product_id"
    case planType = "plan_type"
    case price = "price"
    case currency = "currency"

    // MARK: - Share parameters

    case shareType = "share_type"
}
