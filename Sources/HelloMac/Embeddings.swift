import Foundation
import NaturalLanguage

/// On-device sentence embeddings via Apple's NaturalLanguage framework.
/// No network, no external model files.
final class Embeddings {
    static let shared = Embeddings()

    private let model: NLEmbedding?
    private let lock = NSLock()

    private init() {
        model = NLEmbedding.sentenceEmbedding(for: .english)
        if model == nil {
            print("HelloMac Embeddings: sentence embedding model unavailable; search falls back to keyword-only.")
        }
    }

    var available: Bool { model != nil }

    func embed(_ text: String) -> [Float]? {
        guard let m = model else { return nil }
        let t = String(text.prefix(1000)).replacingOccurrences(of: "\n", with: " ")
        guard !t.trimmingCharacters(in: .whitespaces).isEmpty else { return nil }
        lock.lock()
        defer { lock.unlock() }
        guard let v = m.vector(for: t) else { return nil }
        return v.map { Float($0) }
    }

    static func cosine(_ a: [Float], _ b: [Float]) -> Float {
        var dot: Float = 0, na: Float = 0, nb: Float = 0
        for i in 0..<min(a.count, b.count) {
            dot += a[i] * b[i]
            na += a[i] * a[i]
            nb += b[i] * b[i]
        }
        let denom = (na.squareRoot() * nb.squareRoot())
        return denom > 0 ? dot / denom : 0
    }

    static func data(from vec: [Float]) -> Data {
        return vec.withUnsafeBufferPointer { Data(buffer: $0) }
    }

    static func floats(from data: Data) -> [Float] {
        var arr = [Float](repeating: 0, count: data.count / MemoryLayout<Float>.size)
        _ = arr.withUnsafeMutableBytes { data.copyBytes(to: $0) }
        return arr
    }
}
