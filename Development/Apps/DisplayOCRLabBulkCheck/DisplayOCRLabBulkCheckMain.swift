//
//  DisplayOCRLabBulkCheckMain.swift
//  DisplayOCRLabBulkCheck
//
//  CLI bulk pass/fail for Display OCR training libraries (#677).
//  Usage:
//    DisplayOCRLabBulkCheck <library-root> [--baseline prior.json] [--summary-out out.json]
//  Exit: 0 all scored axes pass; 1 scored failure / baseline regression; 2 usage/IO.
//

import Foundation
import SixLayerFramework

@main
enum DisplayOCRLabBulkCheckMain {
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())
        guard let rootPath = args.first, !rootPath.hasPrefix("-") else {
            fputs(
                "Usage: DisplayOCRLabBulkCheck <library-root> [--baseline prior.json] [--summary-out out.json]\n",
                stderr
            )
            exit(Int32(DisplayOCRLabBulkCheck.usageErrorExitCode))
        }

        var baselinePath: String?
        var summaryOut: String?
        var index = 1
        while index < args.count {
            let flag = args[index]
            switch flag {
            case "--baseline":
                guard index + 1 < args.count else {
                    fputs("Missing path after --baseline\n", stderr)
                    exit(Int32(DisplayOCRLabBulkCheck.usageErrorExitCode))
                }
                baselinePath = args[index + 1]
                index += 2
            case "--summary-out":
                guard index + 1 < args.count else {
                    fputs("Missing path after --summary-out\n", stderr)
                    exit(Int32(DisplayOCRLabBulkCheck.usageErrorExitCode))
                }
                summaryOut = args[index + 1]
                index += 2
            default:
                fputs("Unknown argument: \(flag)\n", stderr)
                exit(Int32(DisplayOCRLabBulkCheck.usageErrorExitCode))
            }
        }

        let root = URL(fileURLWithPath: rootPath, isDirectory: true)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
            fputs("Library root not found or not a directory: \(rootPath)\n", stderr)
            exit(Int32(DisplayOCRLabBulkCheck.usageErrorExitCode))
        }

        let summary: DisplayOCRLabRunSummary
        do {
            summary = try await DisplayOCRLabBulkCheck.runLibrary(at: root)
        } catch {
            fputs("Failed to run bulk check: \(error)\n", stderr)
            exit(Int32(DisplayOCRLabBulkCheck.usageErrorExitCode))
        }

        print(DisplayOCRLabBulkCheck.formatHumanReadable(summary))

        if let summaryOut {
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(summary)
                try data.write(to: URL(fileURLWithPath: summaryOut), options: .atomic)
            } catch {
                fputs("Failed to write summary JSON: \(error)\n", stderr)
                exit(Int32(DisplayOCRLabBulkCheck.usageErrorExitCode))
            }
        }

        var baseline: DisplayOCRLabRunSummary?
        if let baselinePath {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: baselinePath))
                baseline = try JSONDecoder().decode(DisplayOCRLabRunSummary.self, from: data)
            } catch {
                fputs("Failed to read baseline: \(error)\n", stderr)
                exit(Int32(DisplayOCRLabBulkCheck.usageErrorExitCode))
            }
        }

        let code = DisplayOCRLabBulkCheck.exitCode(for: summary, baseline: baseline)
        if let baseline, code == 1 {
            let diff = DisplayOCRLabBulkCheck.compare(current: summary, baseline: baseline)
            if !diff.lostPasses.isEmpty {
                print("baseline lostPasses: \(diff.lostPasses.joined(separator: ", "))")
            }
            if !diff.newFails.isEmpty {
                print("baseline newFails: \(diff.newFails.joined(separator: ", "))")
            }
        }
        exit(Int32(code))
    }
}
