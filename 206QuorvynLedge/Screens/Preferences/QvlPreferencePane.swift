import StoreKit
import SwiftUI

struct QvlPreferencePane: View {
    @EnvironmentObject private var vault: QvlLedgerVault
    @State private var gymDraft = ""
    @State private var confirmClear = false
    @State private var loaded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Wall desk")
                    .font(.title3.weight(.heavy))
                    .foregroundColor(.qvlInk)
                Text("The home wall name is filled in when a new session opens.")
                    .font(.footnote)
                    .foregroundColor(.qvlSlate)
                    .fixedSize(horizontal: false, vertical: true)

                QvlCardShell {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Home wall")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.qvlSlate)
                        TextField("Wall name", text: $gymDraft)
                            .font(.subheadline)
                            .padding(10)
                            .background(Color.qvlTide.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        QvlTideButton(title: "Save wall name") {
                            vault.qvlSetHomeGym(gymDraft)
                            gymDraft = vault.homeGym
                        }
                    }
                }

                QvlCardShell {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Finger tries and rest")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.qvlSlate)
                        Text("Finger tries are counted apart from every try on a line.")
                            .font(.footnote)
                            .foregroundColor(.qvlSlate)
                            .fixedSize(horizontal: false, vertical: true)
                        Stepper(value: Binding(
                            get: { vault.fingerBudget },
                            set: { vault.qvlSetFingerBudget($0) }
                        ), in: 10...120, step: 5) {
                            Text("Finger limit \(vault.fingerBudget)")
                                .font(.subheadline)
                                .foregroundColor(.qvlInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Stepper(value: Binding(
                            get: { vault.restSeconds },
                            set: { vault.qvlSetRestSeconds($0) }
                        ), in: 30...180, step: 15) {
                            Text("Rest between burns \(vault.restSeconds) sec")
                                .font(.subheadline)
                                .foregroundColor(.qvlInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                VStack(spacing: 0) {
                    qvlDeskRow(index: "01", title: "Rate Us", action: rateApp)
                    qvlDeskRow(index: "02", title: "Privacy", action: { qvlOpenLeaf(QvlParchmentGate.privacyLeaf) })
                    qvlDeskRow(index: "03", title: "Terms", action: { qvlOpenLeaf(QvlParchmentGate.termsLeaf) })
                }
                .background(Color.white)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 2, bottomLeadingRadius: 14, bottomTrailingRadius: 2, topTrailingRadius: 14))
                .overlay(alignment: .leading) {
                    Rectangle().fill(Color.qvlTide).frame(width: 5)
                }

                Button("Replay the wall notes") { vault.qvlReplayIntro() }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.qvlTide)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button("Clear sessions and routes") { confirmClear = true }
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.qvlSlate)
                    .frame(maxWidth: .infinity, alignment: .leading)

                QvlFramedStill(name: "QvlWarmStretch", height: 110)
            }
            .padding(16)
        }
        .qvlFoldInkOnTap()
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle("Desk")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            guard !loaded else { return }
            loaded = true
            gymDraft = vault.homeGym
        }
        .alert("Clear the ledge?", isPresented: $confirmClear) {
            Button("Remove logs", role: .destructive) { vault.qvlClearLedge() }
            Button("Leave them", role: .cancel) {}
        } message: {
            Text("Sessions, problems, and today's marks will be removed from this phone.")
        }
    }

    private func qvlDeskRow(index: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(index)
                    .font(.caption.monospaced().weight(.bold))
                    .foregroundColor(.qvlTide)
                    .frame(width: 28, alignment: .leading)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.qvlInk)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption.weight(.bold))
                    .foregroundColor(.qvlSlate)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 12)
        }
        .buttonStyle(.plain)
    }

    private func qvlOpenLeaf(_ leaf: String) {
        if let url = URL(string: leaf) {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
