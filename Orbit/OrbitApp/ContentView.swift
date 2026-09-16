import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "widget.small")
                .font(.system(size: 48))
            Text("Orbit")
                .font(.title)
            Text("Add the Orbit widget from the macOS widget gallery.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(minWidth: 360, minHeight: 240)
    }
}

#Preview {
    ContentView()
}
