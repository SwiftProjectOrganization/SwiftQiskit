import Foundation

public extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let paddingCount = max(0, toLength - count)
        return String(repeating: String(character), count: paddingCount) + self
    }
}
