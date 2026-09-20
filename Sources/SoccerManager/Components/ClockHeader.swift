import SwiftUI
import SoccerManagerCore

/// The Live screen's header: a phase label or subtitle, a countdown, and,
/// at kickoff and halftime, the single pill that starts the next half.
/// Rendered as a card pinned above the scrolling field and bench lists; it
/// never scrolls itself.
///
/// The countdown never auto-stops: once elapsed time in a running half
/// reaches the configured half length it keeps counting as overtime, shown
/// with a leading `+` in Algeria red. At kickoff and halftime the countdown
/// always shows the full half length, a preview of what the next half will
/// count down from, not a stale computation from the half that just ended.
/// Every player's own stint and total keep counting up regardless.
struct ClockHeader: View {
    let snapshot: GameSnapshot
    let phase: GamePhase
    let onStartHalf: () -> Void

    @AppStorage(AppSettings.halfLengthMinutesKey)
    private var halfLengthMinutes = AppSettings.defaultHalfLengthMinutes

    private var halfLengthSeconds: TimeInterval { TimeInterval(halfLengthMinutes * 60) }

    private var displaySeconds: TimeInterval {
        switch phase {
        case .kickoff, .halftime, .fullTime:
            return halfLengthSeconds
        case .firstHalf, .secondHalf:
            return halfLengthSeconds - snapshot.elapsedInHalf
        }
    }

    private var isOvertime: Bool {
        switch phase {
        case .firstHalf, .secondHalf: return displaySeconds <= 0
        case .kickoff, .halftime, .fullTime: return false
        }
    }

    /// The label shown below the countdown: "Kickoff" and "Halftime" name
    /// the phase itself, while "1st half" and "2nd half" are plain
    /// subtitles for the two running phases.
    private var subtitle: String {
        switch phase {
        case .kickoff: return "Kickoff"
        case .firstHalf: return "1st half"
        case .halftime: return "Halftime"
        case .secondHalf: return "2nd half"
        case .fullTime: return "Full time"
        }
    }

    /// The next-half pill's label, shown only at kickoff and halftime.
    private var startButtonTitle: String? {
        switch phase {
        case .kickoff: return "Start 1st half"
        case .halftime: return "Start 2nd half"
        case .firstHalf, .secondHalf, .fullTime: return nil
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            countdownText
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .monospacedDigit()
                .fixedSize()

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let startButtonTitle {
                Button(action: onStartHalf) {
                    Text(startButtonTitle)
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .tint(Color.algeriaGreen)
                .padding(.top, 2)
            }
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
            Text("+\(formatClock(-displaySeconds))")
                .foregroundStyle(Color.algeriaRed)
        } else {
            Text(formatClock(displaySeconds))
                .foregroundStyle(.primary)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ClockHeader(
            snapshot: GameSnapshot(clockRunning: false, currentHalf: 1, elapsedInHalf: 0, elapsedTotal: 0),
            phase: .kickoff,
            onStartHalf: {}
        )
        ClockHeader(
            snapshot: GameSnapshot(clockRunning: true, currentHalf: 1, elapsedInHalf: 754, elapsedTotal: 754),
            phase: .firstHalf,
            onStartHalf: {}
        )
        ClockHeader(
            snapshot: GameSnapshot(clockRunning: false, currentHalf: 1, elapsedInHalf: 1200, elapsedTotal: 1200),
            phase: .halftime,
            onStartHalf: {}
        )
    }
    .background(Color(.systemGray6))
}
