import Foundation
// usage: harness <file.pgm> [localize 0|1] [deskew deg]
let a = CommandLine.arguments
let data = try! Data(contentsOf: URL(fileURLWithPath: a[1]))
// parse binary PGM P5
var idx = 0; var fields: [Int] = []
let bytes = [UInt8](data)
func skipWS() { while idx < bytes.count, [9,10,13,32].contains(bytes[idx]) { idx += 1 } }
idx = 2
while fields.count < 3 { skipWS(); var n = 0; while idx < bytes.count, bytes[idx] >= 48, bytes[idx] <= 57 { n = n*10 + Int(bytes[idx]-48); idx += 1 }; fields.append(n) }
idx += 1
let w = fields[0], h = fields[1]
let img = CGImage(width: w, height: h, gray: Array(bytes[idx..<(idx + w*h)]))
let loc = a.count > 2 ? a[2] == "1" : false
let deg = a.count > 3 ? Double(a[3])! : 3
let t0 = Date()
if loc, let r = SevenSegmentOCR.digitPanelRegion(in: img) { print("panel", r) }
let r = SevenSegmentOCR.decode(cgImage: img, deskewMaximumDegrees: deg, localizeDigitPanel: loc)
print("RESULT \(r.extractedText.debugDescription) conf \(r.confidence) t=\(String(format: "%.1f", Date().timeIntervalSince(t0)))s")
