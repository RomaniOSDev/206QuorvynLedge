import SwiftUI

struct QvlEntryFoldPane: View {
    @EnvironmentObject private var vault: QvlLedgerVault
    @State private var marked: Set<Int> = []

    private let slips: [(image: String, title: String, body: String)] = [
        ("QvlWallBanner", "Log every try", "Write the grade, the attempts, and whether you topped out. The wall history stays on this phone."),
        ("QvlWarmStretch", "Warm up with a plan", "A short circuit is ready each day. Mark a move when you finish it, then climb."),
        ("QvlChalkStill", "Return tomorrow", "Open the ledge, mark the daily focus, and the visit streak keeps growing.")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Mark the wall notes")
                    .font(.title2.weight(.heavy))
                    .foregroundColor(.qvlInk)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Tap a note to mark it. Logging opens after all three are marked.")
                    .font(.subheadline)
                    .foregroundColor(.qvlSlate)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(Array(slips.enumerated()), id: \.offset) { index, slip in
                    Button {
                        if marked.contains(index) {
                            marked.remove(index)
                        } else {
                            marked.insert(index)
                        }
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            QvlFramedStill(name: slip.image, height: 72)
                                .frame(width: 88)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(slip.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.qvlInk)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(slip.body)
                                    .font(.caption)
                                    .foregroundColor(.qvlSlate)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Image(systemName: marked.contains(index) ? "checkmark.square.fill" : "square")
                                .foregroundColor(.qvlTide)
                        }
                        .padding(10)
                        .background(Color.white)
                        .clipShape(UnevenRoundedRectangle(topLeadingRadius: 2, bottomLeadingRadius: 14, bottomTrailingRadius: 2, topTrailingRadius: 14))
                        .overlay(alignment: .leading) {
                            Rectangle().fill(marked.contains(index) ? Color.qvlTide : Color.qvlSlate.opacity(0.35)).frame(width: 4)
                        }
                    }
                    .buttonStyle(.plain)
                }

                QvlTideButton(title: marked.count == slips.count ? "Start logging" : "Mark the next note") {
                    if marked.count == slips.count {
                        vault.qvlMarkIntroCleared()
                    } else if let next = (0..<slips.count).first(where: { !marked.contains($0) }) {
                        marked.insert(next)
                    }
                }
            }
            .padding(16)
        }
        .qvlParchmentBackdrop("QvlWallBanner", veil: 0)
    }
}
