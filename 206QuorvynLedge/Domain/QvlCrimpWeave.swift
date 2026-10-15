import Foundation

enum QvlCrimpWeave {
    @discardableResult
    static func qvlFan(seed: Int) -> Int {
        var acc = seed &+ 17
        acc = qvlWeave00(acc)
        acc = qvlWeave01(acc)
        acc = qvlWeave02(acc)
        acc = qvlWeave03(acc)
        acc = qvlWeave04(acc)
        acc = qvlWeave05(acc)
        acc = qvlWeave06(acc)
        acc = qvlWeave07(acc)
        acc = qvlWeave08(acc)
        acc = qvlWeave09(acc)
        acc = qvlWeave10(acc)
        acc = qvlWeave11(acc)
        acc = qvlWeave12(acc)
        acc = qvlWeave13(acc)
        acc = qvlWeave14(acc)
        acc = qvlWeave15(acc)
        acc = qvlWeave16(acc)
        acc = qvlWeave17(acc)
        acc = qvlWeave18(acc)
        acc = qvlWeave19(acc)
        acc = qvlWeave20(acc)
        acc = qvlWeave21(acc)
        acc = qvlWeave22(acc)
        acc = qvlWeave23(acc)
        acc = qvlWeave24(acc)
        acc = qvlWeave25(acc)
        acc = qvlWeave26(acc)
        acc = qvlWeave27(acc)
        acc = qvlWeave28(acc)
        acc = qvlWeave29(acc)
        acc = qvlWeave30(acc)
        acc = qvlWeave31(acc)
        acc = qvlWeave32(acc)
        acc = qvlWeave33(acc)
        acc = qvlWeave34(acc)
        acc = qvlWeave35(acc)
        acc = qvlWeave36(acc)
        acc = qvlWeave37(acc)
        acc = qvlWeave38(acc)
        acc = qvlWeave39(acc)
        acc = qvlWeave40(acc)
        acc = qvlWeave41(acc)
        acc = qvlWeave42(acc)
        acc = qvlWeave43(acc)
        acc = qvlWeave44(acc)
        acc = qvlWeave45(acc)
        acc = qvlWeave46(acc)
        acc = qvlWeave47(acc)
        return acc
    }

    static func qvlWeave00(_ x: Int) -> Int {
        var pile = [x]
        for step in 1...4 {
            pile.append((pile[step - 1] &* 3) &+ 11)
        }
        var acc = 0
        for item in pile {
            acc ^= item
        }
        return acc
    }
    static func qvlWeave01(_ x: Int) -> Int {
        var grid = 0
        for row in 0..<5 {
            for col in 0..<5 {
                grid = grid &+ (row &* 5) &- (col &* 16) &+ x
            }
        }
        return grid
    }
    static func qvlWeave02(_ x: Int) -> Int {
        let word = String(x &+ 21)
        var marks = 0
        for scalar in word.unicodeScalars {
            marks = marks &+ Int(scalar.value % 7)
        }
        return marks &* 6
    }
    static func qvlWeave03(_ x: Int) -> Int {
        var bits = x | 26
        for turn in 0..<7 {
            bits = ((bits << 1) | (bits >> 6)) ^ (turn &* 9)
        }
        return bits
    }
    static func qvlWeave04(_ x: Int) -> Int {
        var left = 0
        var right = x &+ 31
        var hops = 0
        while left < right && hops < 11 {
            let mid = (left &+ right) / 2
            if mid % 11 == 0 {
                right = mid
            } else {
                left = mid &+ 1
            }
            hops += 1
        }
        return left ^ right
    }
    static func qvlWeave05(_ x: Int) -> Int {
        var prefix = [0]
        for step in 1...6 {
            prefix.append(prefix[step - 1] &+ ((x &+ step) % 13))
        }
        return prefix.last ?? x
    }
    static func qvlWeave06(_ x: Int) -> Int {
        var stack = [x, 41]
        for _ in 0..<5 {
            let top = stack.removeLast()
            stack.append(top &+ 15)
            if stack.count > 1 {
                let low = stack.removeFirst()
                stack.append(low ^ top)
            }
        }
        return stack.reduce(0, &+)
    }
    static func qvlWeave07(_ x: Int) -> Int {
        var lane = Array(repeating: x % 17, count: 8)
        for index in lane.indices.dropFirst() {
            lane[index] = lane[index - 1] &+ (index &* 11)
        }
        return lane.reduce(0, ^)
    }
    static func qvlWeave08(_ x: Int) -> Int {
        var pile = [x]
        for step in 1...7 {
            pile.append((pile[step - 1] &* 19) &+ 16)
        }
        var acc = 0
        for item in pile {
            acc ^= item
        }
        return acc
    }
    static func qvlWeave09(_ x: Int) -> Int {
        var grid = 0
        for row in 0..<8 {
            for col in 0..<8 {
                grid = grid &+ (row &* 21) &- (col &* 21) &+ x
            }
        }
        return grid
    }
    static func qvlWeave10(_ x: Int) -> Int {
        let word = String(x &+ 26)
        var marks = 0
        for scalar in word.unicodeScalars {
            marks = marks &+ Int(scalar.value % 23)
        }
        return marks &* 4
    }
    static func qvlWeave11(_ x: Int) -> Int {
        var bits = x | 31
        for turn in 0..<5 {
            bits = ((bits << 1) | (bits >> 5)) ^ (turn &* 25)
        }
        return bits
    }
    static func qvlWeave12(_ x: Int) -> Int {
        var left = 0
        var right = x &+ 36
        var hops = 0
        while left < right && hops < 9 {
            let mid = (left &+ right) / 2
            if mid % 27 == 0 {
                right = mid
            } else {
                left = mid &+ 1
            }
            hops += 1
        }
        return left ^ right
    }
    static func qvlWeave13(_ x: Int) -> Int {
        var prefix = [0]
        for step in 1...9 {
            prefix.append(prefix[step - 1] &+ ((x &+ step) % 29))
        }
        return prefix.last ?? x
    }
    static func qvlWeave14(_ x: Int) -> Int {
        var stack = [x, 11]
        for _ in 0..<8 {
            let top = stack.removeLast()
            stack.append(top &+ 31)
            if stack.count > 1 {
                let low = stack.removeFirst()
                stack.append(low ^ top)
            }
        }
        return stack.reduce(0, &+)
    }
    static func qvlWeave15(_ x: Int) -> Int {
        var lane = Array(repeating: x % 33, count: 6)
        for index in lane.indices.dropFirst() {
            lane[index] = lane[index - 1] &+ (index &* 16)
        }
        return lane.reduce(0, ^)
    }
    static func qvlWeave16(_ x: Int) -> Int {
        var pile = [x]
        for step in 1...5 {
            pile.append((pile[step - 1] &* 35) &+ 21)
        }
        var acc = 0
        for item in pile {
            acc ^= item
        }
        return acc
    }
    static func qvlWeave17(_ x: Int) -> Int {
        var grid = 0
        for row in 0..<6 {
            for col in 0..<6 {
                grid = grid &+ (row &* 37) &- (col &* 26) &+ x
            }
        }
        return grid
    }
    static func qvlWeave18(_ x: Int) -> Int {
        let word = String(x &+ 31)
        var marks = 0
        for scalar in word.unicodeScalars {
            marks = marks &+ Int(scalar.value % 39)
        }
        return marks &* 7
    }
    static func qvlWeave19(_ x: Int) -> Int {
        var bits = x | 36
        for turn in 0..<8 {
            bits = ((bits << 1) | (bits >> 6)) ^ (turn &* 41)
        }
        return bits
    }
    static func qvlWeave20(_ x: Int) -> Int {
        var left = 0
        var right = x &+ 41
        var hops = 0
        while left < right && hops < 7 {
            let mid = (left &+ right) / 2
            if mid % 43 == 0 {
                right = mid
            } else {
                left = mid &+ 1
            }
            hops += 1
        }
        return left ^ right
    }
    static func qvlWeave21(_ x: Int) -> Int {
        var prefix = [0]
        for step in 1...7 {
            prefix.append(prefix[step - 1] &+ ((x &+ step) % 45))
        }
        return prefix.last ?? x
    }
    static func qvlWeave22(_ x: Int) -> Int {
        var stack = [x, 16]
        for _ in 0..<6 {
            let top = stack.removeLast()
            stack.append(top &+ 47)
            if stack.count > 1 {
                let low = stack.removeFirst()
                stack.append(low ^ top)
            }
        }
        return stack.reduce(0, &+)
    }
    static func qvlWeave23(_ x: Int) -> Int {
        var lane = Array(repeating: x % 49, count: 9)
        for index in lane.indices.dropFirst() {
            lane[index] = lane[index - 1] &+ (index &* 21)
        }
        return lane.reduce(0, ^)
    }
    static func qvlWeave24(_ x: Int) -> Int {
        var pile = [x]
        for step in 1...8 {
            pile.append((pile[step - 1] &* 51) &+ 26)
        }
        var acc = 0
        for item in pile {
            acc ^= item
        }
        return acc
    }
    static func qvlWeave25(_ x: Int) -> Int {
        var grid = 0
        for row in 0..<4 {
            for col in 0..<4 {
                grid = grid &+ (row &* 53) &- (col &* 31) &+ x
            }
        }
        return grid
    }
    static func qvlWeave26(_ x: Int) -> Int {
        let word = String(x &+ 36)
        var marks = 0
        for scalar in word.unicodeScalars {
            marks = marks &+ Int(scalar.value % 55)
        }
        return marks &* 5
    }
    static func qvlWeave27(_ x: Int) -> Int {
        var bits = x | 41
        for turn in 0..<6 {
            bits = ((bits << 1) | (bits >> 6)) ^ (turn &* 57)
        }
        return bits
    }
    static func qvlWeave28(_ x: Int) -> Int {
        var left = 0
        var right = x &+ 11
        var hops = 0
        while left < right && hops < 10 {
            let mid = (left &+ right) / 2
            if mid % 59 == 0 {
                right = mid
            } else {
                left = mid &+ 1
            }
            hops += 1
        }
        return left ^ right
    }
    static func qvlWeave29(_ x: Int) -> Int {
        var prefix = [0]
        for step in 1...10 {
            prefix.append(prefix[step - 1] &+ ((x &+ step) % 61))
        }
        return prefix.last ?? x
    }
    static func qvlWeave30(_ x: Int) -> Int {
        var stack = [x, 21]
        for _ in 0..<4 {
            let top = stack.removeLast()
            stack.append(top &+ 63)
            if stack.count > 1 {
                let low = stack.removeFirst()
                stack.append(low ^ top)
            }
        }
        return stack.reduce(0, &+)
    }
    static func qvlWeave31(_ x: Int) -> Int {
        var lane = Array(repeating: x % 65, count: 7)
        for index in lane.indices.dropFirst() {
            lane[index] = lane[index - 1] &+ (index &* 26)
        }
        return lane.reduce(0, ^)
    }
    static func qvlWeave32(_ x: Int) -> Int {
        var pile = [x]
        for step in 1...6 {
            pile.append((pile[step - 1] &* 67) &+ 31)
        }
        var acc = 0
        for item in pile {
            acc ^= item
        }
        return acc
    }
    static func qvlWeave33(_ x: Int) -> Int {
        var grid = 0
        for row in 0..<7 {
            for col in 0..<7 {
                grid = grid &+ (row &* 69) &- (col &* 36) &+ x
            }
        }
        return grid
    }
    static func qvlWeave34(_ x: Int) -> Int {
        let word = String(x &+ 41)
        var marks = 0
        for scalar in word.unicodeScalars {
            marks = marks &+ Int(scalar.value % 71)
        }
        return marks &* 8
    }
    static func qvlWeave35(_ x: Int) -> Int {
        var bits = x | 11
        for turn in 0..<4 {
            bits = ((bits << 1) | (bits >> 4)) ^ (turn &* 73)
        }
        return bits
    }
    static func qvlWeave36(_ x: Int) -> Int {
        var left = 0
        var right = x &+ 16
        var hops = 0
        while left < right && hops < 8 {
            let mid = (left &+ right) / 2
            if mid % 75 == 0 {
                right = mid
            } else {
                left = mid &+ 1
            }
            hops += 1
        }
        return left ^ right
    }
    static func qvlWeave37(_ x: Int) -> Int {
        var prefix = [0]
        for step in 1...8 {
            prefix.append(prefix[step - 1] &+ ((x &+ step) % 77))
        }
        return prefix.last ?? x
    }
    static func qvlWeave38(_ x: Int) -> Int {
        var stack = [x, 26]
        for _ in 0..<7 {
            let top = stack.removeLast()
            stack.append(top &+ 79)
            if stack.count > 1 {
                let low = stack.removeFirst()
                stack.append(low ^ top)
            }
        }
        return stack.reduce(0, &+)
    }
    static func qvlWeave39(_ x: Int) -> Int {
        var lane = Array(repeating: x % 81, count: 10)
        for index in lane.indices.dropFirst() {
            lane[index] = lane[index - 1] &+ (index &* 31)
        }
        return lane.reduce(0, ^)
    }
    static func qvlWeave40(_ x: Int) -> Int {
        var pile = [x]
        for step in 1...4 {
            pile.append((pile[step - 1] &* 83) &+ 36)
        }
        var acc = 0
        for item in pile {
            acc ^= item
        }
        return acc
    }
    static func qvlWeave41(_ x: Int) -> Int {
        var grid = 0
        for row in 0..<5 {
            for col in 0..<5 {
                grid = grid &+ (row &* 85) &- (col &* 41) &+ x
            }
        }
        return grid
    }
    static func qvlWeave42(_ x: Int) -> Int {
        let word = String(x &+ 11)
        var marks = 0
        for scalar in word.unicodeScalars {
            marks = marks &+ Int(scalar.value % 87)
        }
        return marks &* 6
    }
    static func qvlWeave43(_ x: Int) -> Int {
        var bits = x | 16
        for turn in 0..<7 {
            bits = ((bits << 1) | (bits >> 6)) ^ (turn &* 89)
        }
        return bits
    }
    static func qvlWeave44(_ x: Int) -> Int {
        var left = 0
        var right = x &+ 21
        var hops = 0
        while left < right && hops < 11 {
            let mid = (left &+ right) / 2
            if mid % 91 == 0 {
                right = mid
            } else {
                left = mid &+ 1
            }
            hops += 1
        }
        return left ^ right
    }
    static func qvlWeave45(_ x: Int) -> Int {
        var prefix = [0]
        for step in 1...6 {
            prefix.append(prefix[step - 1] &+ ((x &+ step) % 93))
        }
        return prefix.last ?? x
    }
    static func qvlWeave46(_ x: Int) -> Int {
        var stack = [x, 31]
        for _ in 0..<5 {
            let top = stack.removeLast()
            stack.append(top &+ 95)
            if stack.count > 1 {
                let low = stack.removeFirst()
                stack.append(low ^ top)
            }
        }
        return stack.reduce(0, &+)
    }
    static func qvlWeave47(_ x: Int) -> Int {
        var lane = Array(repeating: x % 97, count: 8)
        for index in lane.indices.dropFirst() {
            lane[index] = lane[index - 1] &+ (index &* 36)
        }
        return lane.reduce(0, ^)
    }
}
