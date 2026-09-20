import Foundation
import SwiftData

/// Debug scaffolding read once at startup, harmless in production since a
/// real launch never carries these arguments. Lets the simulator jump
/// straight to a specific screen and data state for review screenshots.
enum LaunchArguments {
    /// Applies every recognized flag found in `ProcessInfo`'s launch
    /// arguments, in a fixed order: reset, then seed roster, then the
    /// finished-games and autostart fixtures.
    static func apply(context: ModelContext) {
        let args = Set(ProcessInfo.processInfo.arguments)

        if args.contains("-resetData") {
            SeedData.resetAll(context: context)
        }
        if args.contains("-seedRoster") {
            SeedData.seedRosterIfNeeded(context: context)
        }
        if args.contains("-seedFinishedGames") {
            SeedData.seedFinishedGames(context: context)
        }
        if args.contains("-autostartLiveGame") {
            SeedData.autostartLiveGame(context: context, stopped: false)
        }
        // Stopped is halftime now: with the clock-flow header, the only
        // way to be stopped mid-game (not transient full time) is at the
        // break between halves, so both flags seed the same fixture.
        if args.contains("-autostartLiveGameStopped") {
            SeedData.autostartLiveGame(context: context, stopped: true)
        }
        if args.contains("-autostartHalftime") {
            SeedData.autostartLiveGame(context: context, stopped: true)
        }
        if args.contains("-autostartLiveGameSetup") {
            SeedData.autostartLiveGameSetup(context: context)
        }
        if args.contains("-autostartLiveGameOvertime") {
            SeedData.autostartLiveGameOvertime(context: context)
        }
    }
}
