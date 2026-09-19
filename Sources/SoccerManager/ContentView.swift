import SwiftUI
import SoccerManagerCore

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Soccer Manager")
                .font(.largeTitle)
            Text(coreVersion())
                .font(.footnote)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
