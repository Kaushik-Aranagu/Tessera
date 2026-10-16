import Foundation

// Usage:
//   Bench <sd|grdb> build <oneTx|perWorkout> <dir>   build the fixture into a fresh store
//   Bench <sd|grdb> query <dir>                      cold open (fresh process) + read + records + log
//   Bench suite <runs> <workDir> [engines...]        orchestrate subprocesses, print medians
let args = CommandLine.arguments
let selfPath = URL(fileURLWithPath: args[0]).resolvingSymlinksInPath().path

func run(_ arguments: [String]) throws -> [String: Double] {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: selfPath)
    process.arguments = arguments
    let pipe = Pipe()
    process.standardOutput = pipe
    try process.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    let text = String(decoding: data, as: UTF8.self)
    FileHandle.standardError.write(Data(text.utf8))
    guard process.terminationStatus == 0 else { throw NSError(domain: "bench", code: Int(process.terminationStatus)) }
    var results: [String: Double] = [:]
    for line in text.split(separator: "\n") where line.hasPrefix("RESULT ") {
        let parts = line.split(separator: " ")
        results[String(parts[1])] = Double(parts[2])
    }
    return results
}

switch (args.count > 1 ? args[1] : "", args.count > 2 ? args[2] : "") {
case let (engine, "build"):
    let dir = URL(fileURLWithPath: args[4])
    try? FileManager.default.removeItem(at: dir)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    if engine == "sd" {
        try MainActor.assumeIsolated { try SDBench.build(dir: dir, mode: args[3]) }
    } else {
        try GRDBBench.build(dir: dir, perWorkout: args[3] != "oneTx")
    }
    result("\(engine).sizeKB.\(args[3])", Double(directorySize(dir)) / 1024)
case let (engine, "query"):
    let dir = URL(fileURLWithPath: args[3])
    if engine == "sd" {
        try MainActor.assumeIsolated { try SDBench.query(dir: dir) }
    } else {
        try GRDBBench.query(dir: dir)
    }
    result("\(engine).sizeKB.afterLog", Double(directorySize(dir)) / 1024)
case ("suite", _):
    let runs = Int(args[2]) ?? 3
    let work = URL(fileURLWithPath: args[3])
    let engines = args.count > 4 ? Array(args[4...]) : ["grdb", "sd"]
    var all: [String: [Double]] = [:]
    for runIndex in 1 ... runs {
        for engine in engines {
            let modes = (ProcessInfo.processInfo.environment["SPIKE_MODES_\(engine)"] ?? "oneTx,perWorkout")
                .split(separator: ",").map(String.init)
            for mode in modes {
                let dir = work.appending(path: "\(engine)-\(mode)").path
                for (key, value) in try run([engine, "build", mode, dir]) { all[key, default: []].append(value) }
            }
            // Cold read on the store built the way the app writes (per-workout transactions).
            let queryStore = ProcessInfo.processInfo.environment["SPIKE_QUERY_\(engine)"] ?? "\(engine)-perWorkout"
            let dir = work.appending(path: queryStore).path
            for (key, value) in try run([engine, "query", dir]) { all[key, default: []].append(value) }
        }
        FileHandle.standardError.write(Data("-- run \(runIndex) done\n".utf8))
    }
    print("MEDIANS over \(runs) runs (ms, or KB for sizeKB):")
    for key in all.keys.sorted() {
        let values = all[key]!.sorted()
        let median = values[values.count / 2]
        print(String(format: "%-28@ median=%10.1f  runs=%@", key as NSString, median,
                     values.map { String(format: "%.1f", $0) }.joined(separator: ",")))
    }
default:
    print("see usage in main.swift")
}
