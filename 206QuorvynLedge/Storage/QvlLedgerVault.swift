import Foundation

struct QvlDiskEnvelope: Codable {
    var sessions: [QvlSessionBundle]
    var problems: [QvlProblemCard]
    var visitDays: [String]
    var warmupDone: [String: [String]]
    var focusDoneDays: [String]
    var onboardingCleared: Bool
    var homeGym: String
    var fingerBudget: Int?
    var fingerTries: [String: Int]?
    var restSeconds: Int?
}

struct QvlBurnMark: Identifiable {
    var id: UUID { slipId }
    var slipId: UUID
    var when: Date
    var tries: Int
    var toppedOut: Bool
    var sessionTitle: String
}

final class QvlLedgerVault: ObservableObject {
    @Published var sessions: [QvlSessionBundle] = []
    @Published var problems: [QvlProblemCard] = []
    @Published var visitDays: [String] = []
    @Published var warmupDone: [String: [String]] = [:]
    @Published var focusDoneDays: [String] = []
    @Published var onboardingCleared = false
    @Published var homeGym = "Main wall"
    @Published var fingerBudget = 40
    @Published var fingerTries: [String: Int] = [:]
    @Published var restSeconds = 90

    private let fileURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let folder = base.appendingPathComponent("QvlLedgerVault", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        fileURL = folder.appendingPathComponent("ledge-envelope.json")
        qvlBootFromDisk()
    }

    func qvlStampVisit() {
        let key = QvlDayStamp.key(Date())
        guard !visitDays.contains(key) else { return }
        visitDays.append(key)
        qvlFlushEnvelope()
    }

    func qvlStreakSpan() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let known = Set(visitDays)
        var span = 0
        for offset in 0..<500 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today),
                  known.contains(QvlDayStamp.key(day)) else { break }
            span += 1
        }
        return span
    }

    func qvlUpsertSession(_ bundle: QvlSessionBundle) {
        if let index = sessions.firstIndex(where: { $0.id == bundle.id }) {
            sessions[index] = bundle
        } else {
            sessions.insert(bundle, at: 0)
        }
        sessions.sort { $0.startedAt > $1.startedAt }
        qvlFlushEnvelope()
    }

    func qvlDropSession(_ id: UUID) {
        sessions.removeAll { $0.id == id }
        qvlFlushEnvelope()
    }

    func qvlSession(_ id: UUID) -> QvlSessionBundle? {
        sessions.first { $0.id == id }
    }

    func qvlUpsertProblem(_ card: QvlProblemCard) {
        if let index = problems.firstIndex(where: { $0.id == card.id }) {
            problems[index] = card
        } else {
            problems.insert(card, at: 0)
        }
        qvlFlushEnvelope()
    }

    func qvlDropProblem(_ id: UUID) {
        problems.removeAll { $0.id == id }
        qvlFlushEnvelope()
    }

    func qvlTogglePin(_ id: UUID) {
        guard let index = problems.firstIndex(where: { $0.id == id }) else { return }
        problems[index].pinned.toggle()
        qvlFlushEnvelope()
    }

    func qvlToggleWarmup(_ cueId: String) {
        let key = QvlDayStamp.key(Date())
        var done = warmupDone[key] ?? []
        if done.contains(cueId) {
            done.removeAll { $0 == cueId }
        } else {
            done.append(cueId)
        }
        warmupDone[key] = done
        qvlFlushEnvelope()
    }

    func qvlWarmupDoneIds() -> Set<String> {
        Set(warmupDone[QvlDayStamp.key(Date())] ?? [])
    }

    func qvlToggleFocus() {
        let key = QvlDayStamp.key(Date())
        if focusDoneDays.contains(key) {
            focusDoneDays.removeAll { $0 == key }
        } else {
            focusDoneDays.append(key)
        }
        qvlFlushEnvelope()
    }

    func qvlFocusDoneToday() -> Bool {
        focusDoneDays.contains(QvlDayStamp.key(Date()))
    }

    func qvlAttachProblem(_ card: QvlProblemCard) {
        let slip = qvlSlip(for: card)
        if let index = sessions.firstIndex(where: { Calendar.current.isDateInToday($0.startedAt) }) {
            sessions[index].slips.append(slip)
        } else {
            let bundle = QvlSessionBundle(
                id: UUID(),
                title: "Wall visit",
                startedAt: Date(),
                minutes: 30,
                gymSpot: homeGym,
                slips: [slip],
                feelMark: 3,
                closingNote: ""
            )
            sessions.insert(bundle, at: 0)
        }
        qvlFlushEnvelope()
    }

    func qvlWeekBuckets() -> [(label: String, attempts: Int, minutes: Int)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let matching = sessions.filter { calendar.isDate($0.startedAt, inSameDayAs: day) }
            let attempts = matching.reduce(0) { partial, session in
                partial + session.slips.reduce(0) { $0 + $1.attemptCount }
            }
            let minutes = matching.reduce(0) { $0 + $1.minutes }
            return (QvlDayStamp.shortWeekday(day), attempts, minutes)
        }
    }

    func qvlFingerTriesToday() -> Int {
        fingerTries[QvlDayStamp.key(Date())] ?? 0
    }

    func qvlFingerRoomLeft() -> Int {
        max(0, fingerBudget - qvlFingerTriesToday())
    }

    func qvlSetFingerBudget(_ value: Int) {
        fingerBudget = min(120, max(10, value))
        qvlFlushEnvelope()
    }

    func qvlSetRestSeconds(_ value: Int) {
        restSeconds = min(180, max(30, value))
        qvlFlushEnvelope()
    }

    func qvlHistory(for card: QvlProblemCard) -> [QvlBurnMark] {
        sessions.flatMap { session in
            session.slips.compactMap { slip -> QvlBurnMark? in
                let linked = slip.problemId == card.id
                let legacy = slip.problemId == nil && slip.gradeBand == card.gradeBand && slip.wallName == card.colorTag
                guard linked || legacy else { return nil }
                return QvlBurnMark(
                    slipId: slip.id,
                    when: session.startedAt,
                    tries: slip.attemptCount,
                    toppedOut: slip.toppedOut,
                    sessionTitle: session.title
                )
            }
        }
        .sorted { $0.when > $1.when }
    }

    func qvlLogBurn(on card: QvlProblemCard, countsOnFingers: Bool) -> Bool {
        if countsOnFingers && qvlFingerTriesToday() >= fingerBudget {
            return false
        }
        if let sessionIndex = sessions.firstIndex(where: { Calendar.current.isDateInToday($0.startedAt) }),
           let slipIndex = sessions[sessionIndex].slips.firstIndex(where: { $0.problemId == card.id }) {
            sessions[sessionIndex].slips[slipIndex].attemptCount += 1
        } else if let sessionIndex = sessions.firstIndex(where: { Calendar.current.isDateInToday($0.startedAt) }) {
            sessions[sessionIndex].slips.append(qvlSlip(for: card))
        } else {
            sessions.insert(
                QvlSessionBundle(
                    id: UUID(),
                    title: "Wall visit",
                    startedAt: Date(),
                    minutes: 30,
                    gymSpot: homeGym,
                    slips: [qvlSlip(for: card)],
                    feelMark: 3,
                    closingNote: ""
                ),
                at: 0
            )
        }
        if countsOnFingers {
            let key = QvlDayStamp.key(Date())
            fingerTries[key, default: 0] += 1
        }
        qvlFlushEnvelope()
        return true
    }

    private func qvlSlip(for card: QvlProblemCard) -> QvlAscentSlip {
        QvlAscentSlip(
            id: UUID(),
            gradeBand: card.gradeBand,
            attemptCount: 1,
            toppedOut: false,
            holdNote: card.setterNote,
            wallName: card.colorTag,
            problemId: card.id
        )
    }

    func qvlSetHomeGym(_ name: String) {
        homeGym = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if homeGym.isEmpty { homeGym = "Main wall" }
        qvlFlushEnvelope()
    }

    func qvlReplayIntro() {
        onboardingCleared = false
        qvlFlushEnvelope()
    }

    func qvlMarkIntroCleared() {
        onboardingCleared = true
        qvlFlushEnvelope()
    }

    func qvlClearLedge() {
        sessions = []
        problems = []
        warmupDone = [:]
        focusDoneDays = []
        fingerTries = [:]
        qvlFlushEnvelope()
    }

    private func qvlBootFromDisk() {
        guard let data = try? Data(contentsOf: fileURL),
              let envelope = try? JSONDecoder().decode(QvlDiskEnvelope.self, from: data) else { return }
        sessions = envelope.sessions.sorted { $0.startedAt > $1.startedAt }
        problems = envelope.problems
        visitDays = envelope.visitDays
        warmupDone = envelope.warmupDone
        focusDoneDays = envelope.focusDoneDays
        onboardingCleared = envelope.onboardingCleared
        homeGym = envelope.homeGym.isEmpty ? "Main wall" : envelope.homeGym
        fingerBudget = envelope.fingerBudget ?? 40
        fingerTries = envelope.fingerTries ?? [:]
        restSeconds = envelope.restSeconds ?? 90
    }

    private func qvlFlushEnvelope() {
        let envelope = QvlDiskEnvelope(
            sessions: sessions,
            problems: problems,
            visitDays: visitDays,
            warmupDone: warmupDone,
            focusDoneDays: focusDoneDays,
            onboardingCleared: onboardingCleared,
            homeGym: homeGym,
            fingerBudget: fingerBudget,
            fingerTries: fingerTries,
            restSeconds: restSeconds
        )
        guard let data = try? JSONEncoder().encode(envelope) else { return }
        let soak = QvlHoldLattice.qvlSoak(bytes: [UInt8](data.prefix(24)), count: sessions.count &+ problems.count)
        let tape = QvlTapeLedger.qvlPress(seed: soak, lanes: max(visitDays.count, 1))
        let side = fileURL.deletingLastPathComponent().appendingPathComponent("hold-braid.txt")
        try? Data("\(soak &+ tape)".utf8).write(to: side, options: .atomic)
        try? data.write(to: fileURL, options: .atomic)
    }
}
