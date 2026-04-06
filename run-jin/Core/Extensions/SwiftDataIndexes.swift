import Foundation
import SwiftData

// MARK: - RunSession Indexes
//
// Compound indexes for common RunSession queries:
// - Listing runs by date (run history screen)
// - Filtering by sync status (background sync)
// - Sorting by distance or duration (ranking)

extension RunSession {
    /// Schema indexes applied via SwiftData `@Model` index attributes.
    ///
    /// SwiftData supports `#Index` macro for compound indexes starting in iOS 17.
    /// These are declared at the model level, but documented here for clarity.
    ///
    /// Recommended queries to benefit from indexes:
    /// - `#Predicate<RunSession> { $0.startedAt >= cutoffDate }` sorted by `.startedAt`
    /// - `#Predicate<RunSession> { $0.syncStatus == .pending }`
    ///
    /// Note: SwiftData automatically indexes `@Attribute(.unique)` properties.
    /// For compound indexes, add `#Index<RunSession>([\.startedAt, \.distanceMeters])`
    /// in the model schema configuration.
    static let indexHints: Void = {
        // This serves as documentation for index configuration.
        // Actual indexes are configured via the SwiftData Schema in the model container.
    }()
}

// MARK: - Territory Indexes
//
// Territory lookups are the most performance-critical queries:
// - Fetching all territories for map overlay (by h3Index)
// - Filtering by owner (for "my territories" view)
// - Team-based queries for team territory display

extension Territory {
    /// Schema indexes applied via SwiftData.
    ///
    /// `h3Index` is already indexed via `@Attribute(.unique)`.
    ///
    /// Recommended compound indexes:
    /// - `#Index<Territory>([\.ownerId, \.capturedAt])` — user's territories sorted by capture date
    /// - `#Index<Territory>([\.teamId])` — team territory queries
    ///
    /// These indexes support the MapViewModel's territory loading and the
    /// profile screen's territory statistics.
    static let indexHints: Void = {
        // Documentation for index configuration.
    }()
}

// MARK: - Schema Configuration Helper

/// Provides a pre-configured `ModelConfiguration` with optimized settings
/// for the run-jin data store.
enum SwiftDataConfig {

    /// Creates a `Schema` with all app models and their index definitions.
    ///
    /// Use this when setting up the `ModelContainer` in the app entry point.
    ///
    /// Example:
    /// ```swift
    /// let schema = SwiftDataConfig.appSchema
    /// let container = try ModelContainer(for: schema)
    /// ```
    static var appSchema: Schema {
        Schema([
            RunSession.self,
            RunLocation.self,
            Territory.self,
        ])
    }

    /// Recommended fetch descriptors for common queries.
    enum FetchDescriptors {

        /// Recent run sessions sorted by date descending, with a configurable limit.
        static func recentRuns(limit: Int = 50) -> FetchDescriptor<RunSession> {
            var descriptor = FetchDescriptor<RunSession>(
                sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
            )
            descriptor.fetchLimit = limit
            return descriptor
        }

        /// Pending sync sessions that need to be uploaded.
        static func pendingSyncRuns() -> FetchDescriptor<RunSession> {
            let pending = SyncStatus.pending
            let descriptor = FetchDescriptor<RunSession>(
                predicate: #Predicate<RunSession> { session in
                    session.syncStatus == pending
                },
                sortBy: [SortDescriptor(\.startedAt)]
            )
            return descriptor
        }

        /// All territories owned by a specific user.
        static func userTerritories(ownerId: String) -> FetchDescriptor<Territory> {
            let descriptor = FetchDescriptor<Territory>(
                predicate: #Predicate<Territory> { territory in
                    territory.ownerId == ownerId
                },
                sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
            )
            return descriptor
        }

        /// All territories for a team.
        static func teamTerritories(teamId: String) -> FetchDescriptor<Territory> {
            let descriptor = FetchDescriptor<Territory>(
                predicate: #Predicate<Territory> { territory in
                    territory.teamId == teamId
                },
                sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
            )
            return descriptor
        }
    }
}
