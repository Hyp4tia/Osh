import Foundation

final class RenderVersionCounter {
    private var version: Int = 0

    func next() -> Int {
        version += 1
        return version
    }
}
