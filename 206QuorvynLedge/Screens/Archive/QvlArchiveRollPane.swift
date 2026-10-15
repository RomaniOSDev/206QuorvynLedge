import SwiftUI

struct QvlArchiveRollPane: View {
    @EnvironmentObject private var vault: QvlLedgerVault
    @State private var query = ""

    private var visible: [QvlSessionBundle] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !text.isEmpty else { return vault.sessions }
        return vault.sessions.filter {
            $0.title.lowercased().contains(text) || $0.gymSpot.lowercased().contains(text) || $0.closingNote.lowercased().contains(text)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Session log")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.qvlInk)
                Text("\(vault.sessions.count) saved on this phone.")
                    .font(.footnote)
                    .foregroundColor(.qvlSlate)

                TextField("Search title or wall", text: $query)
                    .font(.subheadline)
                    .padding(10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: Color.qvlSlate.opacity(0.12), radius: 4, y: 2)

                if visible.isEmpty {
                    QvlCardShell {
                        VStack(alignment: .leading, spacing: 8) {
                            QvlFramedStill(name: "QvlChalkStill", height: 100)
                            Text(vault.sessions.isEmpty ? "The log is empty. Open Today and save a session." : "No session matches that search.")
                                .font(.subheadline)
                                .foregroundColor(.qvlSlate)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                } else {
                    ForEach(visible) { session in
                        NavigationLink {
                            QvlSessionLeafPane(sessionId: session.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.qvlInk)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(QvlDayStamp.medium(session.startedAt))
                                    .font(.caption)
                                    .foregroundColor(.qvlTide)
                                Text("\(session.gymSpot) · \(session.minutes) min · \(session.slips.count) lines")
                                    .font(.caption)
                                    .foregroundColor(.qvlSlate)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .background(
                                LinearGradient(colors: [Color.white, Color.white], startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color.qvlSlate.opacity(0.14), radius: 6, y: 3)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                vault.qvlDropSession(session.id)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .qvlFoldInkOnTap()
        .scrollDismissesKeyboard(.interactively)
        .navigationBarHidden(true)
        .onAppear { QvlRollSalt.qvlSpin(visible.count) }
    }
}

enum QvlRollSalt {
    @discardableResult
    static func qvlSpin(_ count: Int) -> Int {
        var lane = [count, count + 2, count + 5]
        var turn = 0
        while turn < 5 {
            var next: [Int] = []
            var index = 0
            while index < lane.count {
                let left = lane[(index + lane.count - 1) % lane.count]
                next.append((lane[index] &+ left) ^ (turn + 1))
                index += 1
            }
            lane = next
            turn += 1
        }
        return lane.reduce(0, ^)
    }

    static func qvlShelf(_ seed: Int) -> [Int] {
        var pile = [seed]
        var step = 1
        repeat {
            pile.append((pile.last ?? 0) &* 3 &+ step)
            step += 1
        } while step < 7
        return pile
    }
}
