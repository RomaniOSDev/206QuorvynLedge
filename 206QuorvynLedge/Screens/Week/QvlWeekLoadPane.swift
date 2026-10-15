import SwiftUI

struct QvlWeekLoadPane: View {
    @EnvironmentObject private var vault: QvlLedgerVault

    private var ticks: [QvlSendMath.GradeTick] {
        QvlSendMath.gradeTicks(sessions: vault.sessions).filter { $0.tries > 0 }
    }

    private var fortnight: [QvlSendMath.DayPulse] {
        QvlSendMath.dayPulses(sessions: vault.sessions, days: 14)
    }

    private var week: [QvlSendMath.DayPulse] {
        QvlSendMath.dayPulses(sessions: vault.sessions, days: 7)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Wall ledger")
                            .font(.title2.weight(.heavy))
                            .foregroundColor(.qvlInk)
                        Text(QvlChalkCipher.boardMark(for: vault.sessions))
                            .font(.caption.monospaced())
                            .foregroundColor(.qvlCopper)
                    }
                    Spacer()
                    QvlSendArc(share: QvlSendMath.sendShare(sessions: vault.sessions))
                        .frame(width: 108, height: 108)
                }

                Text(QvlSendMath.nextGradeHint(sessions: vault.sessions))
                    .font(.subheadline)
                    .foregroundColor(.qvlInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.qvlPaper)
                    .overlay(alignment: .bottom) {
                        Rectangle().fill(Color.qvlTide).frame(height: 3)
                    }

                if let feel = QvlSendMath.feelSendNote(sessions: vault.sessions) {
                    Text(feel)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.qvlInk)
                }

                QvlCardShell {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Minutes, last 14 days")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.qvlCopper)
                        QvlMinuteTrace(pulses: fortnight)
                        HStack {
                            Text(fortnight.first?.label ?? "")
                            Spacer()
                            Text(fortnight.last?.label ?? "")
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.qvlSlate)
                    }
                }

                QvlCardShell {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tries by grade")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.qvlCopper)
                        if ticks.isEmpty {
                            Text("Grades appear after you log a line.")
                                .font(.footnote)
                                .foregroundColor(.qvlSlate)
                                .fixedSize(horizontal: false, vertical: true)
                        } else {
                            let peak = max(ticks.map(\.tries).max() ?? 1, 1)
                            ForEach(ticks) { tick in
                                HStack(spacing: 8) {
                                    Text(tick.band)
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.qvlInk)
                                        .frame(width: 28, alignment: .leading)
                                    ZStack(alignment: .leading) {
                                        Rectangle()
                                            .fill(Color.qvlSlate.opacity(0.15))
                                        Rectangle()
                                            .fill(Color.qvlTide)
                                            .scaleEffect(x: CGFloat(tick.tries) / CGFloat(peak), anchor: .leading)
                                        Rectangle()
                                            .fill(Color.qvlCopper)
                                            .scaleEffect(x: CGFloat(min(tick.sends, tick.tries)) / CGFloat(peak), anchor: .leading)
                                    }
                                    .frame(height: 10)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                                    Text("\(tick.sends)/\(tick.tries)")
                                        .font(.caption2.monospaced())
                                        .foregroundColor(.qvlSlate)
                                        .frame(width: 42, alignment: .trailing)
                                }
                            }
                            Text("Rust is tries. Green is sends.")
                                .font(.caption2)
                                .foregroundColor(.qvlSlate)
                        }
                    }
                }

                QvlCardShell {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("This week, tries")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.qvlCopper)
                        let peak = max(week.map(\.tries).max() ?? 1, 1)
                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(week) { pulse in
                                VStack(spacing: 4) {
                                    Rectangle()
                                        .fill(pulse.tries == 0 ? Color.qvlSlate.opacity(0.25) : Color.qvlInk)
                                        .frame(width: 8, height: max(4, 88 * CGFloat(pulse.tries) / CGFloat(peak)))
                                    Text(pulse.dayNumber)
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.qvlSlate)
                                }
                                .frame(maxWidth: .infinity, alignment: .bottom)
                            }
                        }
                        .frame(height: 112, alignment: .bottom)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 8)
        }
        .navigationBarHidden(true)
    }
}

struct QvlSendArc: View {
    var share: Double

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.12, to: 0.88)
                .stroke(Color.qvlInk.opacity(0.12), style: StrokeStyle(lineWidth: 10, lineCap: .butt))
                .rotationEffect(.degrees(90))
            Circle()
                .trim(from: 0.12, to: 0.12 + 0.76 * share)
                .stroke(Color.qvlTide, style: StrokeStyle(lineWidth: 10, lineCap: .butt))
                .rotationEffect(.degrees(90))
            Text("\(Int((share * 100).rounded()))%")
                .font(.headline.weight(.heavy))
                .foregroundColor(.qvlInk)
        }
    }
}

struct QvlMinuteTrace: View {
    let pulses: [QvlSendMath.DayPulse]

    var body: some View {
        Canvas { context, size in
            guard pulses.count > 1 else { return }
            let peak = CGFloat(max(pulses.map(\.minutes).max() ?? 1, 1))
            func point(_ index: Int) -> CGPoint {
                let x = size.width * CGFloat(index) / CGFloat(pulses.count - 1)
                let y = size.height - (CGFloat(pulses[index].minutes) / peak) * (size.height - 10) - 4
                return CGPoint(x: x, y: y)
            }
            var line = Path()
            line.move(to: point(0))
            for index in 1..<pulses.count {
                line.addLine(to: point(index))
            }
            context.stroke(line, with: .color(Color.qvlTide), style: StrokeStyle(lineWidth: 2, lineJoin: .round))
            for index in pulses.indices {
                let spot = point(index)
                let dot = Path(ellipseIn: CGRect(x: spot.x - 2.5, y: spot.y - 2.5, width: 5, height: 5))
                context.fill(dot, with: .color(Color.qvlCopper))
            }
        }
        .frame(height: 110)
        .background(Color.qvlParchment.opacity(0.45))
    }
}
