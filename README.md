# Soccer Manager

A sideline tool that tracks each player's field and goalie minutes so playing time stays even.

## Build

1. `xcodegen generate`
2. `xcodebuild -project SoccerManager.xcodeproj -scheme SoccerManager -configuration Debug -destination "platform=iOS Simulator,name=SoccerManager-iPhone" -derivedDataPath /tmp/soccermanager-sim build`
3. `swift test` (run inside `Packages/SoccerManagerCore`)
