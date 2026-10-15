import SwiftUI

struct QvlProblemLeafPane: View {
    let problemId: UUID
    @EnvironmentObject private var vault: QvlLedgerVault
    @Environment(\.dismiss) private var dismiss
    @State private var editing = false
    @State private var confirmDrop = false
    @State private var attachedNote = false
    @State private var countsOnFingers = true
    @State private var restEnds: Date?
    @State private var clock = Date()
    @State private var fingerBlocked = false

    private var card: QvlProblemCard? { vault.problems.first { $0.id == problemId } }
    private var history: [QvlBurnMark] {
        guard let card else { return [] }
        return vault.qvlHistory(for: card)
    }
    private var restLeft: Int {
        guard let restEnds else { return 0 }
        return max(0, Int(restEnds.timeIntervalSince(clock).rounded(.up)))
    }

    var body: some View {
        ScrollView {
            if let card {
                VStack(alignment: .leading, spacing: 14) {
                    QvlFramedStill(name: "QvlTopoutHands", height: 140)
                    QvlCardShell {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(card.name)
                                .font(.title3.weight(.bold))
                                .foregroundColor(.qvlInk)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("\(card.gradeBand) · \(card.colorTag)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.qvlTide)
                            if !card.setterNote.isEmpty {
                                Text(card.setterNote)
                                    .font(.body)
                                    .foregroundColor(.qvlSlate)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Text(card.pinned ? "Pinned in the cabinet" : "Not pinned")
                                .font(.caption)
                                .foregroundColor(.qvlSlate)
                        }
                    }

                    QvlCardShell {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Burns on this route")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.qvlCopper)
                            Text("Finger tries today \(vault.qvlFingerTriesToday()) of \(vault.fingerBudget)")
                                .font(.footnote)
                                .foregroundColor(vault.qvlFingerRoomLeft() == 0 ? .qvlTide : .qvlSlate)
                            Toggle(isOn: $countsOnFingers) {
                                Text("This burn counts on the fingers")
                                    .font(.subheadline)
                                    .foregroundColor(.qvlInk)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .tint(.qvlTide)
                            if restLeft > 0 {
                                Text(String(format: "Rest %02d:%02d", restLeft / 60, restLeft % 60))
                                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                                    .foregroundColor(.qvlInk)
                                QvlGhostButton(title: "Skip rest") { restEnds = nil }
                            } else {
                                QvlTideButton(title: "Log a burn") { qvlBurn(card) }
                            }
                        }
                    }

                    if history.isEmpty {
                        Text("No burns yet. Log one and the list stays on this route.")
                            .font(.footnote)
                            .foregroundColor(.qvlSlate)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Attempt history")
                            .font(.headline)
                            .foregroundColor(.qvlInk)
                        ForEach(history) { mark in
                            VStack(alignment: .leading, spacing: 3) {
                                Text(mark.sessionTitle)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.qvlInk)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text("\(QvlDayStamp.medium(mark.when)) · \(mark.tries) tries · \(mark.toppedOut ? "Sent" : "Open")")
                                    .font(.caption)
                                    .foregroundColor(.qvlSlate)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(Color.qvlPaper)
                        }
                    }

                    QvlTideButton(title: "Add to today's session") {
                        vault.qvlAttachProblem(card)
                        attachedNote = true
                    }
                    QvlGhostButton(title: card.pinned ? "Unpin" : "Pin") {
                        vault.qvlTogglePin(card.id)
                    }
                    QvlGhostButton(title: "Edit problem") { editing = true }
                    Button("Remove from cabinet") { confirmDrop = true }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.qvlTide)
                        .frame(maxWidth: .infinity)
                }
                .padding(16)
                .sheet(isPresented: $editing) {
                    QvlProblemComposerSheet(existing: card)
                }
            } else {
                Text("This problem was removed.")
                    .foregroundColor(.qvlSlate)
                    .padding(20)
            }
        }
        .navigationTitle("Problem")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { date in
            clock = date
            if let restEnds, restEnds <= date { self.restEnds = nil }
        }
        .alert("Added to today", isPresented: $attachedNote) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("A line was placed on today's session. Open Today to adjust attempts.")
        }
        .alert("Finger limit reached", isPresented: $fingerBlocked) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Today's finger tries are at \(vault.fingerBudget). Turn off the finger count or raise the limit in Settings.")
        }
        .confirmationDialog("Remove this problem?", isPresented: $confirmDrop, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                vault.qvlDropProblem(problemId)
                dismiss()
            }
            Button("Keep", role: .cancel) {}
        }
    }

    private func qvlBurn(_ card: QvlProblemCard) {
        guard vault.qvlLogBurn(on: card, countsOnFingers: countsOnFingers) else {
            fingerBlocked = true
            return
        }
        restEnds = Date().addingTimeInterval(TimeInterval(vault.restSeconds))
    }
}
