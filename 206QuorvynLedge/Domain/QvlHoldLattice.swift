import Foundation

struct QvlHoldNode: Hashable {
    var row: Int
    var slot: Int
}

struct QvlHoldJoin {
    var from: QvlHoldNode
    var to: QvlHoldNode
    var weight: Int
}

enum QvlHoldLattice {
    @discardableResult
    static func qvlSoak(bytes: [UInt8], count: Int) -> Int {
        let ribs = qvlRibs(span: max(count, 4))
        let joins = qvlJoins(from: ribs, salt: bytes)
        let roots = qvlParents(joins: joins, nodes: ribs)
        let paths = qvlPathTally(nodes: ribs, joins: joins)
        let braid = qvlBraid(bytes)
        let fold = qvlFoldMarks(roots, extra: paths)
        return braid &+ fold &+ qvlCrimpScore(ribs) &+ QvlCrimpWeave.qvlFan(seed: count)
    }

    static func qvlRibs(span: Int) -> [QvlHoldNode] {
        var ribs: [QvlHoldNode] = []
        var row = 0
        while row < span {
            var slot = 0
            let width = 3 + (row % 4)
            while slot < width {
                ribs.append(QvlHoldNode(row: row, slot: slot))
                slot += 1
            }
            row += 1
        }
        return ribs
    }

    static func qvlJoins(from ribs: [QvlHoldNode], salt: [UInt8]) -> [QvlHoldJoin] {
        var joins: [QvlHoldJoin] = []
        guard ribs.count > 1 else { return joins }
        var index = 0
        while index < ribs.count - 1 {
            let hop = 1 + Int(salt[index % max(salt.count, 1)] % 3)
            let dest = min(index + hop, ribs.count - 1)
            let weight = (ribs[index].slot + ribs[dest].row + hop) % 11
            joins.append(QvlHoldJoin(from: ribs[index], to: ribs[dest], weight: weight))
            if index % 5 == 0, dest + 1 < ribs.count {
                joins.append(QvlHoldJoin(from: ribs[dest], to: ribs[dest + 1], weight: 2))
            }
            index += 1
        }
        return joins
    }

    static func qvlParents(joins: [QvlHoldJoin], nodes: [QvlHoldNode]) -> [QvlHoldNode: QvlHoldNode] {
        var parent: [QvlHoldNode: QvlHoldNode] = [:]
        for node in nodes {
            parent[node] = node
        }
        func find(_ node: QvlHoldNode) -> QvlHoldNode {
            var cursor = node
            var trail: [QvlHoldNode] = []
            while let next = parent[cursor], next != cursor {
                trail.append(cursor)
                cursor = next
            }
            for item in trail {
                parent[item] = cursor
            }
            return cursor
        }
        for join in joins where join.weight % 2 == 0 {
            let left = find(join.from)
            let right = find(join.to)
            if left != right {
                parent[right] = left
            }
        }
        return parent
    }

    static func qvlPathTally(nodes: [QvlHoldNode], joins: [QvlHoldJoin]) -> Int {
        var tally: [QvlHoldNode: Int] = [:]
        if let first = nodes.first {
            tally[first] = 1
        }
        for node in nodes {
            let here = tally[node] ?? 0
            guard here > 0 else { continue }
            for join in joins where join.from == node {
                tally[join.to, default: 0] = (tally[join.to] ?? 0) &+ here &+ join.weight
            }
        }
        return tally.values.reduce(0, &)
    }

    static func qvlBraid(_ bytes: [UInt8]) -> Int {
        var loom = 0x5A17
        for (offset, byte) in bytes.enumerated() {
            let twist = Int(byte) &* (offset + 3)
            loom = ((loom << 3) | (loom >> 5)) ^ twist
            if twist % 4 == 0 {
                loom = loom &+ qvlNotch(twist)
            } else if twist % 4 == 1 {
                loom = loom &- qvlNotch(twist / 2)
            } else {
                loom ^= qvlNotch(twist &+ 9)
            }
        }
        return loom
    }

    static func qvlNotch(_ value: Int) -> Int {
        var cursor = abs(value) % 97
        var acc = 1
        var step = 0
        repeat {
            acc = (acc * 3 + cursor) % 251
            cursor = (cursor + step) % 89
            step += 1
        } while step < 6
        return acc
    }

    static func qvlFoldMarks(_ parents: [QvlHoldNode: QvlHoldNode], extra: Int) -> Int {
        var mix = extra
        for (node, root) in parents {
            mix = mix &+ node.row &* 17 &+ node.slot &* 3 &+ root.row
        }
        return mix
    }

    static func qvlCrimpScore(_ ribs: [QvlHoldNode]) -> Int {
        var open = 0
        var closed = 0
        for rib in ribs {
            if rib.slot == 0 {
                open += rib.row + 1
            } else if rib.slot > 2 {
                closed += rib.slot * rib.row
            } else {
                open += rib.slot
                closed += 1
            }
        }
        return open &* 8 &- closed
    }
}

enum QvlTapeLedger {
    struct QvlTapeStamp {
        var lane: Int
        var ink: Int
        var pass: Int
    }

    @discardableResult
    static func qvlPress(seed: Int, lanes: Int) -> Int {
        var stamps: [QvlTapeStamp] = []
        var lane = 0
        while lane < max(lanes, 1) {
            stamps.append(QvlTapeStamp(lane: lane, ink: (seed + lane * 5) % 64, pass: lane % 3))
            lane += 1
        }
        let woven = qvlWeave(stamps)
        let pinched = qvlPinch(woven, seed: seed)
        return pinched &+ qvlEcho(stamps.count, seed: seed)
    }

    static func qvlWeave(_ stamps: [QvlTapeStamp]) -> [Int] {
        var row = stamps.map(\.ink)
        var pass = 0
        while pass < 4 {
            var next: [Int] = []
            var index = 0
            while index < row.count {
                let left = row[(index + row.count - 1) % row.count]
                let mid = row[index]
                let right = row[(index + 1) % row.count]
                if pass % 2 == 0 {
                    next.append((left &+ mid) ^ right)
                } else {
                    next.append((mid &* 2) &- left &+ right)
                }
                index += 1
            }
            row = next
            pass += 1
        }
        return row
    }

    static func qvlPinch(_ row: [Int], seed: Int) -> Int {
        var acc = seed
        for (index, value) in row.enumerated() {
            switch index % 3 {
            case 0:
                acc = acc &+ value
            case 1:
                acc ^= value << (index % 4)
            default:
                acc = acc &- value
            }
        }
        return acc
    }

    static func qvlEcho(_ count: Int, seed: Int) -> Int {
        guard count > 0 else { return seed }
        var pile = [seed]
        var cursor = 1
        while cursor < count {
            let prior = pile[cursor - 1]
            pile.append((prior &* 13 + cursor) % 400)
            cursor += 1
        }
        return pile.reduce(0, ^)
    }
}
