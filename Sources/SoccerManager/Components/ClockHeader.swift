import SwiftUI
import SoccerManagerCore

/// The Live screen's header: half picker, a countdown to the end of the
/// half, a status subtitle, and the single Start/Stop control. Rendered as
/// a card pinned above the scrolling field and bench lists; it never
/// scrolls itself.
///
/// The countdown never auto-stops: once elapsed time in the half reaches
/// the configured half length it keeps counting as overtime, shown with a
/// leading `+` in Algeria red. Every player's own stint and total keep
/// counting up regardless, unaffected by this display.
struct ClockHeader: View {
    let snapshot: GameSnapshot
    @Binding var selectedHalf: Int
    let onToggleClock: () -> Void

    @AppStorage(AppSettings.halfLengthMinutesKey)
    private var halfLengthMinutes = AppSettings.defaultHalfLengthMinutes

    private var halfLengthSeconds: TimeInterval { TimeInterval(halfLengthMinutes * 60) }
    private var remaining: TimeInterval { halfLengthSeconds - snapshot.elapsedInHalf }
    private var isOvertime: Bool { remaining <= 0 }

    var body: some View {
        VStack(spacing: 2) {
            Picker("Half", selection: $selectedHalf) {
                Text("1st").tag(1)
                Text("2nd").tag(2)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 150)
            .disabled(snapshot.clockRunning)

            countdownText
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .monospacedDigit()
                .fixedSize()

            Text("\(selectedHalf == 1 ? "1st half" : "2nd half") \u{00B7} \(snapshot.clockRunning ? "Running" : "Stopped")")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: onToggleClock) {
                Text(snapshot.clockRunning ? "Stop" : "Start")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(snapshot.clockRunning ? Color.algeriaRed : Color.algeriaGreen)
            .padding(.top, 2)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
        )
        .padding(.horizontal, 12)
        .padding(.top, 4)
    }

    /// The countdown to the end of the half, or `+m:ss` of overtime once
    /// elapsed time reaches or passes the half length.
    @ViewBuilder
    private var countdownText: some View {
        if isOvertime {
            Text("+\(formatClock(-remaining))")
                .foregroundStyle(Color.algeriaRed)
        } else {
            Text(formatClock(remaining))
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ClockHeader(
            snapshot: GameSnapshot(clockRunning: true, currentHalf: 1, elapsedInHalf: 754, elapsedTotal: 754),
            selectedHalf: .constant(1),
            onToggleClock: {}
        )
        ClockHeader(
            snapshot: GameSnapshot(clockRunning: true, currentHalf: 2, elapsedInHalf: 1260, elapsedTotal: 1260),
            selectedHalf: .constant(2),
            onToggleClock: {}
        )
    }
    .background(Color(.systemGray6))
}
