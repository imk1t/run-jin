import SwiftData
import SwiftUI

struct RunHistoryView: View {
    @Query(sort: \RunSession.startedAt, order: .reverse)
    private var sessions: [RunSession]

    var body: some View {
        Group {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "まだランニング記録がありません",
                    systemImage: "figure.run",
                    description: Text("ランニングを完了すると、ここに記録が表示されます")
                )
            } else {
                List(sessions) { session in
                    NavigationLink {
                        RunDetailView(session: session)
                    } label: {
                        RunHistoryRow(session: session)
                    }
                }
            }
        }
        .navigationTitle("ラン履歴")
    }
}

private struct RunHistoryRow: View {
    let session: RunSession

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.startedAt, style: .date)
                    .font(.headline)
                Text(session.startedAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formattedDistance)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                HStack(spacing: 8) {
                    Label(formattedDuration, systemImage: "clock")
                    Label(formattedPace, systemImage: "speedometer")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var formattedDistance: String {
        FormatHelpers.distanceKmWithUnit(meters: session.distanceMeters)
    }

    private var formattedDuration: String {
        FormatHelpers.duration(seconds: session.durationSeconds)
    }

    private var formattedPace: String {
        FormatHelpers.paceWithUnit(secondsPerKm: session.avgPaceSecondsPerKm)
    }
}

#Preview {
    NavigationStack {
        RunHistoryView()
    }
    .modelContainer(for: [RunSession.self, RunLocation.self], inMemory: true)
}
