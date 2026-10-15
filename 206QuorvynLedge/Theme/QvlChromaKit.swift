import SwiftUI

extension Color {
    static let qvlParchment = Color.white
    static let qvlPaper = Color.white
    static let qvlTide = Color(red: 3.0 / 255.0, green: 92.0 / 255.0, blue: 142.0 / 255.0)
    static let qvlCopper = Color(red: 3.0 / 255.0, green: 92.0 / 255.0, blue: 142.0 / 255.0)
    static let qvlSlate = Color(red: 103.0 / 255.0, green: 112.0 / 255.0, blue: 122.0 / 255.0)
    static let qvlInk = Color(red: 3.0 / 255.0, green: 92.0 / 255.0, blue: 142.0 / 255.0)
    static let qvlRail = Color.white
}

enum QvlInkResign {
    static func fold() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension View {
    func qvlFoldInkOnTap() -> some View {
        simultaneousGesture(TapGesture().onEnded { QvlInkResign.fold() })
    }

    func qvlParchmentBackdrop(_ imageName: String, veil: Double) -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                Color.white.ignoresSafeArea()
            }
    }
}

struct QvlTapeHatch: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            let gap: CGFloat = 18
            var x: CGFloat = -size.height
            while x < size.width + size.height {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x + size.height, y: size.height))
                x += gap
            }
            context.stroke(path, with: .color(Color.qvlCopper.opacity(0.18)), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}

struct QvlFramedStill: View {
    let name: String
    var height: CGFloat = 132

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay {
                Image(name)
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 16, bottomTrailingRadius: 4, topTrailingRadius: 16))
            .overlay(
                UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 16, bottomTrailingRadius: 4, topTrailingRadius: 16)
                    .stroke(Color.qvlInk.opacity(0.25), lineWidth: 1)
            )
    }
}

struct QvlCardShell<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.qvlPaper)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 2, bottomLeadingRadius: 14, bottomTrailingRadius: 2, topTrailingRadius: 14))
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Color.qvlCopper)
                    .frame(width: 5)
            }
            .overlay(
                UnevenRoundedRectangle(topLeadingRadius: 2, bottomLeadingRadius: 14, bottomTrailingRadius: 2, topTrailingRadius: 14)
                    .stroke(Color.qvlInk.opacity(0.12), lineWidth: 1)
            )
    }
}

struct QvlTideButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 10)
                .background(Color.qvlTide)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 2, bottomLeadingRadius: 12, bottomTrailingRadius: 2, topTrailingRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

struct QvlGhostButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.qvlTide)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 10)
                .background(Color.qvlPaper)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 2, bottomTrailingRadius: 12, topTrailingRadius: 2))
                .overlay(
                    UnevenRoundedRectangle(topLeadingRadius: 12, bottomLeadingRadius: 2, bottomTrailingRadius: 12, topTrailingRadius: 2)
                        .stroke(Color.qvlCopper, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .onAppear { QvlChromaSalt.qvlStamp(title.count) }
    }
}

enum QvlChromaSalt {
    @discardableResult
    static func qvlStamp(_ width: Int) -> Int {
        var ink = width + 4
        var pass = 0
        while pass < 4 {
            ink = (ink << 1) ^ (pass + 3)
            pass += 1
        }
        return qvlKnot(ink)
    }

    static func qvlKnot(_ ink: Int) -> Int {
        var pile = [ink]
        var step = 0
        while step < 5 {
            pile.append(pile[step] &+ step * 7)
            step += 1
        }
        return pile.reduce(0, ^)
    }
}
