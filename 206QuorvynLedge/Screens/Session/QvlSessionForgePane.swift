import SwiftUI

struct QvlSessionForgePane: View {
    var existingId: UUID? = nil
    @EnvironmentObject private var vault: QvlLedgerVault
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var gymSpot = ""
    @State private var minutes = 45
    @State private var feelMark = 3
    @State private var closingNote = ""
    @State private var slips: [QvlAscentSlip] = []
    @State private var ticking = false
    @State private var elapsed = 0
    @State private var showSlipSheet = false
    @State private var faultLine = ""
    @State private var showFault = false
    @State private var loaded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                QvlFramedStill(name: "QvlTopoutHands", height: 110)

                if vault.qvlWarmupDoneIds().isEmpty {
                    QvlCardShell {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Warmup is not marked")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.qvlTide)
                            Text("The circuit for today is still empty. Mark it before the harder lines.")
                                .font(.footnote)
                                .foregroundColor(.qvlSlate)
                                .fixedSize(horizontal: false, vertical: true)
                            NavigationLink {
                                QvlWarmupCircuitPane()
                            } label: {
                                Text("Open warmup")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.qvlCopper)
                            }
                        }
                    }
                }

                QvlCardShell {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(ticking ? "Timer running" : "Session timer")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.qvlTide)
                        Text(qvlClock(elapsed))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.qvlInk)
                        HStack(spacing: 8) {
                            QvlTideButton(title: ticking ? "Pause" : "Start") { ticking.toggle() }
                            QvlGhostButton(title: "Reset") {
                                ticking = false
                                elapsed = 0
                            }
                        }
                    }
                }

                QvlCardShell {
                    VStack(alignment: .leading, spacing: 10) {
                        qvlField("Title", text: $title)
                        qvlField("Wall or gym", text: $gymSpot)
                        Stepper(value: $minutes, in: 5...300, step: 5) {
                            Text("Minutes \(minutes)")
                                .font(.subheadline)
                                .foregroundColor(.qvlInk)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Stepper(value: $feelMark, in: 1...5) {
                            Text("Effort \(feelMark) of 5")
                                .font(.subheadline)
                                .foregroundColor(.qvlInk)
                        }
                        Text("Closing note")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.qvlSlate)
                        TextField("How the session felt", text: $closingNote, axis: .vertical)
                            .font(.subheadline)
                            .padding(10)
                            .background(Color.qvlTide.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }

                HStack {
                    Text("Lines")
                        .font(.headline)
                        .foregroundColor(.qvlInk)
                    Spacer()
                    Button("Add a line") { showSlipSheet = true }
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.qvlTide)
                }

                if slips.isEmpty {
                    Text("No lines yet. Add a grade when you try something.")
                        .font(.footnote)
                        .foregroundColor(.qvlSlate)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ForEach(slips) { slip in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(slip.gradeBand) · \(slip.wallName)")
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(.qvlInk)
                                Text("\(slip.attemptCount) tries · \(slip.toppedOut ? "Topped" : "Open")")
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
                            Button {
                                slips.removeAll { $0.id == slip.id }
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.qvlTide)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.qvlSlate.opacity(0.12), radius: 5, y: 3)
                    }
                }

                QvlTideButton(title: existingId == nil ? "Save session" : "Keep changes") {
                    qvlSave()
                }
            }
            .padding(16)
        }
        .qvlFoldInkOnTap()
        .scrollDismissesKeyboard(.interactively)
        .navigationTitle(existingId == nil ? "New session" : "Edit session")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: qvlLoad)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if ticking { elapsed += 1 }
        }
        .onDisappear { ticking = false }
        .sheet(isPresented: $showSlipSheet) {
            QvlSlipComposerSheet { slip in
                slips.append(slip)
            }
        }
        .alert("Check the session", isPresented: $showFault) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(faultLine)
        }
    }

    private func qvlField(_ caption: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(caption)
                .font(.caption.weight(.bold))
                .foregroundColor(.qvlSlate)
            TextField(caption, text: text)
                .font(.subheadline)
                .padding(10)
                .background(Color.qvlTide.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func qvlClock(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    private func qvlLoad() {
        guard !loaded else { return }
        loaded = true
        gymSpot = vault.homeGym
        guard let existingId, let bundle = vault.qvlSession(existingId) else { return }
        title = bundle.title
        gymSpot = bundle.gymSpot
        minutes = bundle.minutes
        feelMark = bundle.feelMark
        closingNote = bundle.closingNote
        slips = bundle.slips
    }

    private func qvlSave() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            faultLine = "Add a short title before saving."
            showFault = true
            return
        }
        let timed = elapsed / 60
        let finalMinutes = timed > 0 ? max(timed, 1) : minutes
        if finalMinutes < 1 {
            faultLine = "Add minutes or run the timer."
            showFault = true
            return
        }
        let spot = gymSpot.trimmingCharacters(in: .whitespacesAndNewlines)
        let bundle = QvlSessionBundle(
            id: existingId ?? UUID(),
            title: trimmed,
            startedAt: vault.qvlSession(existingId ?? UUID())?.startedAt ?? Date(),
            minutes: finalMinutes,
            gymSpot: spot.isEmpty ? vault.homeGym : spot,
            slips: slips,
            feelMark: feelMark,
            closingNote: closingNote.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        vault.qvlUpsertSession(bundle)
        dismiss()
    }
}

struct QvlSlipComposerSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (QvlAscentSlip) -> Void

    @State private var gradeBand = "V2"
    @State private var attempts = 1
    @State private var topped = false
    @State private var wallName = "Blue"
    @State private var holdNote = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Grade")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.qvlSlate)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(QvlGradeRibbon.bands, id: \.self) { band in
                                Button(band) { gradeBand = band }
                                    .font(.subheadline.weight(.bold))
                                    .foregroundColor(gradeBand == band ? .white : .qvlTide)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(gradeBand == band ? Color.qvlTide : Color.qvlTide.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    Stepper(value: $attempts, in: 1...40) {
                        Text("Attempts \(attempts)")
                            .foregroundColor(.qvlInk)
                    }
                    Toggle(isOn: $topped) {
                        Text("Topped out")
                            .foregroundColor(.qvlInk)
                    }
                    .tint(.qvlTide)
                    Text("Hold color")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.qvlSlate)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(QvlGradeRibbon.colorTags, id: \.self) { tag in
                                Button(tag) { wallName = tag }
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(wallName == tag ? .white : .qvlSlate)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 8)
                                    .background(wallName == tag ? Color.qvlSlate : Color.qvlSlate.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    TextField("Note about the moves", text: $holdNote, axis: .vertical)
                        .font(.subheadline)
                        .padding(10)
                        .background(Color.qvlTide.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    QvlTideButton(title: "Add this line") {
                        onSave(QvlAscentSlip(
                            id: UUID(),
                            gradeBand: gradeBand,
                            attemptCount: attempts,
                            toppedOut: topped,
                            holdNote: holdNote.trimmingCharacters(in: .whitespacesAndNewlines),
                            wallName: wallName
                        ))
                        dismiss()
                    }
                }
                .padding(16)
            }
            .qvlFoldInkOnTap()
            .navigationTitle("New line")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
