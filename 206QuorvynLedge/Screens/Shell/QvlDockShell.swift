import SwiftUI

enum QvlDockLane: String, CaseIterable, Identifiable {
    case today
    case cabinet
    case warmup
    case week
    case archive

    var id: String { rawValue }

    var label: String {
        switch self {
        case .today: return "Today"
        case .cabinet: return "Routes"
        case .warmup: return "Warmup"
        case .week: return "Stats"
        case .archive: return "Log"
        }
    }

    var symbol: String {
        switch self {
        case .today: return "sun.max.fill"
        case .cabinet: return "square.stack.3d.up.fill"
        case .warmup: return "figure.walk"
        case .week: return "chart.line.uptrend.xyaxis"
        case .archive: return "book.closed.fill"
        }
    }
}

struct QvlDockShell: View {
    @State private var lane: QvlDockLane = .today

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch lane {
                case .today:
                    NavigationStack { QvlTodayLedgePane() }
                case .cabinet:
                    NavigationStack { QvlProblemCabinetPane() }
                case .warmup:
                    NavigationStack { QvlWarmupCircuitPane() }
                case .week:
                    NavigationStack { QvlWeekLoadPane() }
                case .archive:
                    NavigationStack { QvlArchiveRollPane() }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack(spacing: 0) {
                ForEach(QvlDockLane.allCases) { item in
                    Button {
                        withAnimation(.easeOut(duration: 0.18)) { lane = item }
                    } label: {
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .stroke(lane == item ? Color.qvlTide : Color.qvlSlate, lineWidth: 1.5)
                                    .frame(width: 28, height: 28)
                                Circle()
                                    .fill(lane == item ? Color.qvlTide : Color.white)
                                    .frame(width: 18, height: 18)
                                Image(systemName: item.symbol)
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(lane == item ? .white : .qvlSlate)
                            }
                            Text(item.label)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(lane == item ? .qvlTide : .qvlSlate)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.qvlRail)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color.qvlTide)
                    .frame(height: 3)
            }
        }
        .qvlParchmentBackdrop("QvlChalkStill", veil: 0.08)
    }
}
