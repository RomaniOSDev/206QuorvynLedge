import SwiftUI

struct QvlWarmupCircuitPane: View {
    @EnvironmentObject private var vault: QvlLedgerVault

    private var done: Set<String> { vault.qvlWarmupDoneIds() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                QvlFramedStill(name: "QvlWarmStretch", height: 150)
                Text("Daily warmup")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.qvlInk)
                Text("\(done.count) of \(QvlWarmupCatalog.cues.count) marked today. The list clears after midnight.")
                    .font(.footnote)
                    .foregroundColor(.qvlSlate)
                    .fixedSize(horizontal: false, vertical: true)

                GeometryReader { proxy in
                    let width = proxy.size.width
                    let ratio = CGFloat(done.count) / CGFloat(QvlWarmupCatalog.cues.count)
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.qvlSlate.opacity(0.18))
                        Capsule()
                            .fill(LinearGradient(colors: [Color.qvlTide, Color.qvlTide.opacity(0.7)], startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(8, width * ratio))
                    }
                }
                .frame(height: 10)

                ForEach(QvlWarmupCatalog.cues) { cue in
                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                            vault.qvlToggleWarmup(cue.id)
                        }
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: done.contains(cue.id) ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundColor(done.contains(cue.id) ? .qvlTide : .qvlSlate)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(cue.title)
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.qvlInk)
                                    .fixedSize(horizontal: false, vertical: true)
                                Text(cue.detail)
                                    .font(.footnote)
                                    .foregroundColor(.qvlSlate)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(done.contains(cue.id) ? Color.qvlTide.opacity(0.45) : Color.clear, lineWidth: 1.5)
                        )
                        .shadow(color: Color.qvlSlate.opacity(0.12), radius: 6, y: 3)
                    }
                    .buttonStyle(.plain)
                }

                if !done.isEmpty {
                    QvlGhostButton(title: "Clear today's marks") {
                        done.forEach { vault.qvlToggleWarmup($0) }
                    }
                }
            }
            .padding(16)
        }
        .navigationBarHidden(true)
    }
}
