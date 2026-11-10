import Foundation
public typealias CFData = Data
public func CFDataGetLength(_ d: Data) -> Int { d.count }
public func CFDataGetBytePtr(_ d: Data) -> [UInt8]? { [UInt8](d) }
public final class CGDataProvider { let data: Data?; public init?(data: Data) { self.data = data } }
public struct CGColorSpace {}
public func CGColorSpaceCreateDeviceGray() -> CGColorSpace { CGColorSpace() }
public enum CGImageAlphaInfo: UInt32 { case none = 0 }
public struct CGBitmapInfo { public let rawValue: UInt32; public init(rawValue: UInt32) { self.rawValue = rawValue } }
public enum CGColorRenderingIntent { case defaultIntent }
extension CGImage {
    public convenience init?(width: Int, height: Int, bitsPerComponent: Int, bitsPerPixel: Int, bytesPerRow: Int,
        space: CGColorSpace, bitmapInfo: CGBitmapInfo, provider: CGDataProvider, decode: [CGFloat]?, shouldInterpolate: Bool, intent: CGColorRenderingIntent) {
        let bytes = [UInt8](provider.data ?? Data())
        var g = [UInt8](repeating: 0, count: width * height)
        for y in 0..<height { for x in 0..<width { g[y*width+x] = bytes[y*bytesPerRow+x] } }
        self.init(width: width, height: height, gray: g)
    }
    public var dataProvider: CGDataProvider? { CGDataProvider(data: Data(gray)) }
    public var bytesPerRow: Int { width }
}
struct RequireError: Error {}
func require<T>(_ v: T?, file: String = #file, line: Int = #line) throws -> T { guard let v else { expect(false, file: file, line: line); throw RequireError() }; return v }
nonisolated(unsafe) var current = ""
nonisolated(unsafe) var failures: [String: [Int]] = [:]
nonisolated(unsafe) var order: [String] = []
func expect(_ c: @autoclosure () -> Bool, _ msg: @autoclosure () -> String = "", file: String = #file, line: Int = #line) {
    if !c() { failures[current, default: []].append(line) }
}
func run(_ name: String, _ body: () throws -> Void) {
    current = name; order.append(name)
    do { try body() } catch { failures[name, default: []].append(-1) }
}
func report() {
    let only = ProcessInfo.processInfo.environment["QUIET"] != nil
    for n in order { if let f = failures[n] { print("FAIL \(n) lines \(f)") } else if !only { print("pass \(n)") } }
    print("\(order.count - failures.count)/\(order.count) passed")
}
