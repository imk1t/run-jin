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
                    NavigationLink(value: Route.runDetail(id: session.id.uuidString)) {
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
        let km = session.distanceMeters / 1000.0
        return String(format: "%.2f km", km)
    }

    private var formattedDuration: String {
        let minutes = session.durationSeconds / 60
        let seconds = session.durationSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var formattedPace: String {
        guard let pace = session.avgPaceSecondsPerKm else { return "--:--" }
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d/km", minutes, seconds)
    }
}

#Preview {
    NavigationStack {
        RunHistoryView()
    }
    .modelContainer(for: [RunSession.self, RunLocation.self], inMemory: true)
}
