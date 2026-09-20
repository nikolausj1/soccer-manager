import SwiftUI
import SoccerManagerCore

/// The Live screen's header: half picker, elapsed-in-half clock, a status
/// subtitle, and the single Start/Stop control. A fixed region pinned above
/// the scrolling field and bench lists; it never scrolls itself.
struct ClockHeader: View {
    let snapshot: GameSnapshot
    @Binding var selectedHalf: Int
    let onToggleClock: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Picker("Half", selection: $selectedHalf) {
                Text("1st").tag(1)
                Text("2nd").tag(2)
            }
            .pickerStyle(.segmented)
            .disabled(snapshot.clockRunning)

            Text(formatClock(snapshot.elapsedInHalf))
                .font(.system(size: 56, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(.primary)

            Text("\(selectedHalf == 1 ? "1st half" : "2nd half") \u{00B7} \(snapshot.clockRunning ? "Running" : "Stopped")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: onToggleClock) {
                Text(snapshot.clockRunning ? "Stop" : "Start")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity, minHeight: 52)
            }
            .buttonStyle(.borderedProminent)
            .tint(snapshot.clockRunning ? Color.algeriaRed : Color.algeriaGreen)
        }
        .padding(.horizontal)
        .padding(.top, 4)
        .padding(.bottom, 4)
        .background(Color.white)
    }
}

#Preview {
    ClockHeader(
        snapshot: GameSnapshot(clockRunning: true, currentHalf: 1, elapsedInHalf: 754, elapsedTotal: 754),
        selectedHalf: .constant(1),
        onToggleClock: {}
    )
}
