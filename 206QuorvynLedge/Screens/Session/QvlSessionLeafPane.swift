import SwiftUI

struct QvlSessionLeafPane: View {
    let sessionId: UUID
    @EnvironmentObject private var vault: QvlLedgerVault
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDrop = false

    private var session: QvlSessionBundle? { vault.qvlSession(sessionId) }

    var body: some View {
        ScrollView {
            if let session {
                VStack(alignment: .leading, spacing: 14) {
                    QvlFramedStill(name: "QvlChalkStill", height: 120)
                    QvlCardShell {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(session.title)
                                .font(.title3.weight(.bold))
                                .foregroundColor(.qvlInk)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(QvlDayStamp.medium(session.startedAt))
                                .font(.caption)
                                .foregroundColor(.qvlSlate)
                            Text("\(session.gymSpot) · \(session.minutes) min · effort \(session.feelMark) of 5")
                                .font(.subheadline)
                                .foregroundColor(.qvlInk)
                                .fixedSize(horizontal: false, vertical: true)
                            if !session.closingNote.isEmpty {
                                Text(session.closingNote)
                                    .font(.subheadline)
                                    .foregroundColor(.qvlSlate)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    let topped = session.slips.filter(\.toppedOut).count
                    let attempts = session.slips.reduce(0) { $0 + $1.attemptCount }
                    HStack(spacing: 8) {
                        qvlMini("\(session.slips.count)", "Lines")
                        qvlMini("\(attempts)", "Tries")
                        qvlMini("\(topped)", "Top-outs")
                    }

                    ForEach(session.slips) { slip in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(slip.gradeBand) · \(slip.wallName)")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.qvlInk)
                                Text("\(slip.attemptCount) tries · \(slip.toppedOut ? "Topped" : "Still open")")
                                    .font(.caption)
                                    .foregroundColor(.qvlSlate)
                                if !slip.holdNote.isEmpty {
                                    Text(slip.holdNote)
                                        .font(.caption)
                                        .foregroundColor(.qvlSlate)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.qvlSlate.opacity(0.12), radius: 5, y: 3)
                    }

                    NavigationLink {
                        QvlSessionForgePane(existingId: session.id)
                    } label: {
                        Text("Edit this session")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.qvlTide)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button("Delete session") { confirmDrop = true }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.qvlTide)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .padding(16)
            } else {
                Text("This session is no longer in the log.")
                    .font(.subheadline)
                    .foregroundColor(.qvlSlate)
                    .padding(20)
            }
        }
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this session?", isPresented: $confirmDrop, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                vault.qvlDropSession(sessionId)
                dismiss()
            }
            Button("Keep", role: .cancel) {}
        }
    }

    private func qvlMini(_ value: String, _ caption: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.headline)
                .foregroundColor(.qvlTide)
            Text(caption)
                .font(.caption)
                .foregroundColor(.qvlSlate)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.qvlSlate.opacity(0.12), radius: 5, y: 3)
    }
}
