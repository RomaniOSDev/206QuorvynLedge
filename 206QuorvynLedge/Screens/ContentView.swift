import SwiftUI

struct ContentView: View {
    @StateObject private var vault = QvlLedgerVault()

    var body: some View {
        qvlRoot
            .environmentObject(vault)
            .onAppear { vault.qvlStampVisit() }
    }

    @ViewBuilder
    private var qvlRoot: some View {
        switch vault.onboardingCleared {
        case false:
            QvlEntryFoldPane()
        case true:
            QvlDockShell()
        }
    }
}
