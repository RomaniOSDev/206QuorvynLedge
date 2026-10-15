import SwiftUI

struct QvlTodayLedgePane: View {
    @EnvironmentObject private var vault: QvlLedgerVault
    @State private var pulse = false

    private var focus: (title: String, body: String) { QvlWallFocus.packet(for: Date()) }
    private var todaySessions: [QvlSessionBundle] {
        vault.sessions.filter { Calendar.current.isDateInToday($0.startedAt) }
    }
    private var weekAttempts: Int {
        vault.qvlWeekBuckets().reduce(0) { $0 + $1.attempts }
    }
    private var weekTopouts: Int {
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: Date())) ?? Date()
        return vault.sessions
            .filter { $0.startedAt >= start }
            .reduce(0) { partial, session in partial + session.slips.filter(\.toppedOut).count }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Today on the wall")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.qvlInk)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    NavigationLink {
                        QvlPreferencePane()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.body.weight(.bold))
                            .foregroundColor(.qvlTide)
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.qvlSlate.opacity(0.2), radius: 6, y: 3)
                    }
                }

                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Visit streak")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white.opacity(0.85))
                        Text("\(vault.qvlStreakSpan())")
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .scaleEffect(pulse ? 1 : 0.86)
                        Text(vault.qvlStreakSpan() == 1 ? "day in a row" : "days in a row")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.92))
                    }
                    Spacer()
                    Image(systemName: "flame.fill")
                        .font(.system(size: 34))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [Color.qvlTide, Color.qvlTide.opacity(0.82)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: Color.qvlTide.opacity(0.32), radius: 12, y: 8)

                if let rest = QvlSendMath.skinRest(sessions: vault.sessions) {
                    Text(rest)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.qvlCopper)
                }

                Text("Finger tries \(vault.qvlFingerTriesToday()) of \(vault.fingerBudget)")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(vault.qvlFingerRoomLeft() == 0 ? .qvlTide : .qvlInk)
                    .fixedSize(horizontal: false, vertical: true)

                QvlFramedStill(name: "QvlWallBanner", height: 128)

                QvlCardShell {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Daily focus")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.qvlTide)
                        Text(focus.title)
                            .font(.headline)
                            .foregroundColor(.qvlInk)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(focus.body)
                            .font(.subheadline)
                            .foregroundColor(.qvlSlate)
                            .fixedSize(horizontal: false, vertical: true)
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { vault.qvlToggleFocus() }
                        } label: {
                            Text(vault.qvlFocusDoneToday() ? "Practiced today" : "Mark practiced")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(vault.qvlFocusDoneToday() ? .qvlTide : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(vault.qvlFocusDoneToday() ? Color.qvlTide.opacity(0.12) : Color.qvlTide)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 8) {
                    qvlStatTile(value: "\(todaySessions.count)", caption: "Sessions today")
                    qvlStatTile(value: "\(weekAttempts)", caption: "Tries this week")
                    qvlStatTile(value: "\(weekTopouts)", caption: "Top-outs")
                }

                NavigationLink {
                    QvlSessionForgePane()
                } label: {
                    Text("Open a session")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(colors: [Color.qvlTide, Color.qvlTide.opacity(0.82)], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.qvlTide.opacity(0.25), radius: 8, y: 4)
                }
                .buttonStyle(.plain)

                Text("Today")
                    .font(.headline)
                    .foregroundColor(.qvlInk)

                if todaySessions.isEmpty {
                    QvlCardShell {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("No session yet")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.qvlInk)
                            Text("Start one after warmup. Grades and attempts stay in the log.")
                                .font(.footnote)
                                .foregroundColor(.qvlSlate)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                } else {
                    ForEach(todaySessions) { session in
                        NavigationLink {
                            QvlSessionLeafPane(sessionId: session.id)
                        } label: {
                            qvlSessionRow(session)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 20)
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) { pulse = true }
        }
    }

    private func qvlStatTile(value: String, caption: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(.qvlTide)
            Text(caption)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.qvlSlate)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.qvlSlate.opacity(0.14), radius: 6, y: 3)
    }

    private func qvlSessionRow(_ session: QvlSessionBundle) -> some View {
        HStack(spacing: 10) {
            QvlFramedStill(name: "QvlTopoutHands", height: 54)
                .frame(width: 54)
            VStack(alignment: .leading, spacing: 3) {
                Text(session.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.qvlInk)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(session.minutes) min · \(session.slips.count) lines · \(session.gymSpot)")
                    .font(.caption)
                    .foregroundColor(.qvlSlate)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundColor(.qvlTide)
        }
        .padding(10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.qvlSlate.opacity(0.12), radius: 6, y: 3)
    }
}
