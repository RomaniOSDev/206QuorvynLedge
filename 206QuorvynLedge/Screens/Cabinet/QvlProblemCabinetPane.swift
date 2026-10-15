import SwiftUI

struct QvlProblemCabinetPane: View {
    @EnvironmentObject private var vault: QvlLedgerVault
    @State private var query = ""
    @State private var gradeFilter = "All"
    @State private var showComposer = false

    private var visible: [QvlProblemCard] {
        vault.problems.filter { card in
            let gradeOK = gradeFilter == "All" || card.gradeBand == gradeFilter
            let text = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let textOK = text.isEmpty || card.name.lowercased().contains(text) || card.colorTag.lowercased().contains(text) || card.setterNote.lowercased().contains(text)
            return gradeOK && textOK
        }
        .sorted { lhs, rhs in
            if lhs.pinned != rhs.pinned { return lhs.pinned && !rhs.pinned }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                QvlFramedStill(name: "QvlWallBanner", height: 110)
                Text("Route cabinet")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.qvlInk)
                Text("Save problems you want to revisit. Pin the ones that still feel unfinished.")
                    .font(.footnote)
                    .foregroundColor(.qvlSlate)
                    .fixedSize(horizontal: false, vertical: true)

                TextField("Search name or color", text: $query)
                    .font(.subheadline)
                    .padding(10)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .shadow(color: Color.qvlSlate.opacity(0.12), radius: 4, y: 2)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        gradeChip("All")
                        ForEach(QvlGradeRibbon.bands, id: \.self) { band in
                            gradeChip(band)
                        }
                    }
                }

                QvlTideButton(title: "Save a problem") { showComposer = true }

                if visible.isEmpty {
                    QvlCardShell {
                        Text(vault.problems.isEmpty ? "The cabinet is empty. Add a problem you want to remember." : "Nothing matches this filter.")
                            .font(.subheadline)
                            .foregroundColor(.qvlSlate)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    ForEach(visible) { card in
                        HStack(spacing: 8) {
                            NavigationLink {
                                QvlProblemLeafPane(problemId: card.id)
                            } label: {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(card.name)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundColor(.qvlInk)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text("\(card.gradeBand) · \(card.colorTag)")
                                        .font(.caption)
                                        .foregroundColor(.qvlSlate)
                                    let marks = vault.qvlHistory(for: card)
                                    if !marks.isEmpty {
                                        let tries = marks.reduce(0) { $0 + $1.tries }
                                        let sends = marks.filter(\.toppedOut).count
                                        Text("\(tries) tries · \(sends) sends")
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(.qvlCopper)
                                    }
                                    if !card.setterNote.isEmpty {
                                        Text(card.setterNote)
                                            .font(.caption)
                                            .foregroundColor(.qvlSlate)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                            Button {
                                vault.qvlTogglePin(card.id)
                            } label: {
                                Image(systemName: card.pinned ? "pin.fill" : "pin")
                                    .foregroundColor(.qvlTide)
                                    .frame(width: 36, height: 36)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.qvlSlate.opacity(0.12), radius: 6, y: 3)
                    }
                }
            }
            .padding(16)
        }
        .qvlFoldInkOnTap()
        .scrollDismissesKeyboard(.interactively)
        .navigationBarHidden(true)
        .sheet(isPresented: $showComposer) {
            QvlProblemComposerSheet(existing: nil)
        }
    }

    private func gradeChip(_ title: String) -> some View {
        Button(title) { gradeFilter = title }
            .font(.caption.weight(.bold))
            .foregroundColor(gradeFilter == title ? .white : .qvlTide)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(gradeFilter == title ? Color.qvlTide : Color.white)
            .clipShape(Capsule())
            .shadow(color: Color.qvlSlate.opacity(0.12), radius: 3, y: 2)
    }
}

struct QvlProblemComposerSheet: View {
    var existing: QvlProblemCard?
    @EnvironmentObject private var vault: QvlLedgerVault
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var gradeBand = "V2"
    @State private var colorTag = "Blue"
    @State private var setterNote = ""
    @State private var pinned = false
    @State private var showFault = false
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Problem name", text: $name)
                        .font(.subheadline)
                        .padding(10)
                        .background(Color.qvlTide.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Text("Grade")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.qvlSlate)
                    chipRow(QvlGradeRibbon.bands, selected: gradeBand) { gradeBand = $0 }
                    Text("Color")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.qvlSlate)
                    chipRow(QvlGradeRibbon.colorTags, selected: colorTag) { colorTag = $0 }
                    TextField("What to remember", text: $setterNote, axis: .vertical)
                        .font(.subheadline)
                        .padding(10)
                        .background(Color.qvlTide.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Toggle(isOn: $pinned) {
                        Text("Pin in the cabinet")
                            .foregroundColor(.qvlInk)
                    }
                    .tint(.qvlTide)
                    QvlTideButton(title: existing == nil ? "Save problem" : "Keep problem") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty {
                            showFault = true
                            return
                        }
                        vault.qvlUpsertProblem(QvlProblemCard(
                            id: existing?.id ?? UUID(),
                            name: trimmed,
                            gradeBand: gradeBand,
                            setterNote: setterNote.trimmingCharacters(in: .whitespacesAndNewlines),
                            colorTag: colorTag,
                            pinned: pinned
                        ))
                        dismiss()
                    }
                }
                .padding(16)
            }
            .qvlFoldInkOnTap()
            .navigationTitle(existing == nil ? "New problem" : "Edit problem")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                guard let existing else { return }
                name = existing.name
                gradeBand = existing.gradeBand
                colorTag = existing.colorTag
                setterNote = existing.setterNote
                pinned = existing.pinned
            }
            .alert("Add a name", isPresented: $showFault) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The cabinet needs a name so you can find this problem later.")
            }
        }
    }

    private func chipRow(_ items: [String], selected: String, tap: @escaping (String) -> Void) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(items, id: \.self) { item in
                    Button(item) { tap(item) }
                        .font(.caption.weight(.bold))
                        .foregroundColor(selected == item ? .white : .qvlTide)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(selected == item ? Color.qvlTide : Color.qvlTide.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        }
    }
}
