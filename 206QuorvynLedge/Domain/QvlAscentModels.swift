import Foundation

struct QvlAscentSlip: Identifiable, Codable, Equatable {
    var id: UUID
    var gradeBand: String
    var attemptCount: Int
    var toppedOut: Bool
    var holdNote: String
    var wallName: String
    var problemId: UUID? = nil
}

struct QvlSessionBundle: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var startedAt: Date
    var minutes: Int
    var gymSpot: String
    var slips: [QvlAscentSlip]
    var feelMark: Int
    var closingNote: String
}

struct QvlProblemCard: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var gradeBand: String
    var setterNote: String
    var colorTag: String
    var pinned: Bool
}

struct QvlWarmupCue: Identifiable {
    var id: String
    var title: String
    var detail: String
}

enum QvlGradeRibbon {
    static let bands = ["VB", "V0", "V1", "V2", "V3", "V4", "V5", "V6", "V7", "V8"]
    static let colorTags = ["Yellow", "Green", "Blue", "Red", "Black", "Pink", "Orange", "White"]
}

enum QvlWarmupCatalog {
    static let cues: [QvlWarmupCue] = [
        QvlWarmupCue(id: "wrists", title: "Wrist circles", detail: "Ten slow circles each way. Keep the shoulders dropped."),
        QvlWarmupCue(id: "shoulders", title: "Shoulder openers", detail: "Arm circles, then reach up and out. Stop before a pinch."),
        QvlWarmupCue(id: "hips", title: "Hip hinges", detail: "Eight hinges with a flat back. Feel the hips, not the lower back."),
        QvlWarmupCue(id: "traverse", title: "Easy traverse", detail: "Move sideways on big holds. Quiet feet, straight arms."),
        QvlWarmupCue(id: "feet", title: "Quiet feet", detail: "Five moves where the foot lands without a slap."),
        QvlWarmupCue(id: "hang", title: "Short hang", detail: "Two easy hangs on a large edge. Step off while you still feel fresh.")
    ]
}

enum QvlWallFocus {
    static func packet(for date: Date) -> (title: String, body: String) {
        let weekday = Calendar.current.component(.weekday, from: date)
        switch weekday {
        case 1:
            return ("Quiet feet", "Place the foot, then shift the hip. Keep each step silent.")
        case 2:
            return ("Long hips", "Turn the hip toward the wall before the next hand moves.")
        case 3:
            return ("Straight arms", "Hang on straight arms between the harder moves.")
        case 4:
            return ("Eyes first", "Look at the next hold before you leave the last one.")
        case 5:
            return ("Flag balance", "Flag a leg when both feet want the same side.")
        case 6:
            return ("Soft catches", "Catch the hold with a soft elbow, then settle.")
        default:
            return ("Easy volume", "Climb several easy lines and stop while the form stays tidy.")
        }
    }
}

enum QvlDayStamp {
    static func key(_ date: Date) -> String {
        let calendar = Calendar(identifier: .gregorian)
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let year = parts.year ?? 0
        let month = parts.month ?? 0
        let day = parts.day ?? 0
        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func shortWeekday(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    static func narrowDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    static func medium(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

enum QvlChalkCipher {
    private static let marks = ["△", "○", "□", "◇", "✕"]

    static func boardMark(for sessions: [QvlSessionBundle]) -> String {
        let seed = sessions.reduce(11) { partial, session in
            partial + session.minutes + session.slips.count * 5 + session.feelMark
        }
        return (0..<4).map { offset in
            marks[(seed + offset * 3) % marks.count]
        }.joined(separator: " ")
    }
}

enum QvlSendMath {
    struct GradeTick: Identifiable {
        var id: String { band }
        var band: String
        var tries: Int
        var sends: Int
    }

    struct DayPulse: Identifiable {
        var id: String { key }
        var key: String
        var label: String
        var dayNumber: String
        var minutes: Int
        var tries: Int
    }

    static func gradeTicks(sessions: [QvlSessionBundle]) -> [GradeTick] {
        QvlGradeRibbon.bands.map { band in
            let slips = sessions.flatMap(\.slips).filter { $0.gradeBand == band }
            let tries = slips.reduce(0) { $0 + $1.attemptCount }
            let sends = slips.filter(\.toppedOut).count
            return GradeTick(band: band, tries: tries, sends: sends)
        }
    }

    static func sendShare(sessions: [QvlSessionBundle]) -> Double {
        let slips = sessions.flatMap(\.slips)
        let tries = slips.reduce(0) { $0 + max($1.attemptCount, 0) }
        guard tries > 0 else { return 0 }
        let sends = slips.filter(\.toppedOut).count
        return min(1, Double(sends) / Double(tries))
    }

    static func dayPulses(sessions: [QvlSessionBundle], days: Int, now: Date = Date()) -> [DayPulse] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)
        return (0..<days).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let matching = sessions.filter { calendar.isDate($0.startedAt, inSameDayAs: day) }
            let tries = matching.reduce(0) { partial, session in
                partial + session.slips.reduce(0) { $0 + $1.attemptCount }
            }
            let minutes = matching.reduce(0) { $0 + $1.minutes }
            return DayPulse(
                key: QvlDayStamp.key(day),
                label: QvlDayStamp.shortWeekday(day),
                dayNumber: QvlDayStamp.narrowDay(day),
                minutes: minutes,
                tries: tries
            )
        }
    }

    static func nextGradeHint(sessions: [QvlSessionBundle]) -> String {
        let ticks = gradeTicks(sessions: sessions).filter { $0.sends > 0 }
        guard let top = ticks.last, let index = QvlGradeRibbon.bands.firstIndex(of: top.band) else {
            return "Send one easy line. The next grade shows up after that."
        }
        let share = top.tries == 0 ? 0 : Double(top.sends) / Double(top.tries)
        if share >= 0.5, index + 1 < QvlGradeRibbon.bands.count {
            return "Sends at \(top.band) are sticking. Open with one \(QvlGradeRibbon.bands[index + 1]) while you are fresh."
        }
        return "Stay with \(top.band) until more than half of those tries are sends."
    }

    static func skinRest(sessions: [QvlSessionBundle], now: Date = Date()) -> String? {
        let tries = dayPulses(sessions: sessions, days: 2, now: now).reduce(0) { $0 + $1.tries }
        guard tries >= 40 else { return nil }
        return "Heavy tries across two days. Keep the next session on big holds."
    }

    static func feelSendNote(sessions: [QvlSessionBundle]) -> String? {
        let recent = sessions.sorted { $0.startedAt < $1.startedAt }.suffix(3)
        guard recent.count >= 2 else { return nil }
        let ordered = Array(recent)
        let falling = zip(ordered, ordered.dropFirst()).allSatisfy { $0.feelMark > $1.feelMark }
        guard falling, let latest = ordered.last, latest.slips.filter(\.toppedOut).isEmpty else { return nil }
        return "Effort marks are falling and the latest session has no send. Drop a grade or stop earlier."
    }
}
