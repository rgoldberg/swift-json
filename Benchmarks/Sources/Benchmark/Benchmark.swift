import ArgumentParser
import JSON
import SystemIO
import System_ArgumentParser

struct Benchmark {
    @Argument(
        help: "path to JSON file to parse",
    ) var input: FilePath
}
@main extension Benchmark: ParsableCommand {
    static var configuration: CommandConfiguration {
        .init(commandName: "benchmark")
    }

    func run() throws {
        let clock: ContinuousClock = .init()
        let duration: Duration = try clock.measure {
            let json: JSON = .init(utf8: try self.input.read()[...])
            let root: JSON.Node = try .init(parsing: json)
            Self._blackhole(root)
        }

        print(duration)
    }
}
extension Benchmark {
    @inline(never) private static func _blackhole(_: JSON.Node) {}
}
