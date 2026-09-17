import Foundation
import OrbitCore

/// One reading of Claude Code's quota windows, already normalized to the
/// shared model but not yet attributed to a provider. The last stop before
/// `ClaudeCodeProvider` turns it into a `UsageSnapshot`.
public struct ClaudeCodeUsageReading: Equatable, Sendable {
    public let periods: [UsagePeriod]
    public let generatedAt: Date

    /// Only the API client populates this; the CLI text fallback has no way
    /// to produce it.
    public let analytics: ClaudeUsageAnalytics?

    public init(periods: [UsagePeriod], generatedAt: Date, analytics: ClaudeUsageAnalytics? = nil) {
        self.periods = periods
        self.generatedAt = generatedAt
        self.analytics = analytics
    }
}

/// The I/O boundary for Claude Code usage data. `ClaudeCodeProvider` depends
/// only on this protocol, so changing how usage is obtained — the CLI, a
/// cached file, a future API — touches nothing else.
public protocol ClaudeCodeUsageClient: Sendable {
    func fetchUsage() async throws -> ClaudeCodeUsageReading
}

/// Reads usage by running Claude Code's own `/usage` command and parsing what
/// it prints.
///
/// Two constraints shape this:
///
/// - **It cannot run from the widget.** Widget extensions are sandboxed and
///   have no business spawning processes. The app runs this, caches the
///   result in the App Group, and the widget reads that cache.
/// - **`PATH` is not inherited.** A GUI app launched from Finder gets a
///   minimal environment, so the executable is located explicitly rather than
///   relying on `claude` resolving on the path.
public struct ClaudeCodeCLIUsageClient: ClaudeCodeUsageClient {
    /// Where `claude` is commonly installed, in the order to try. The native
    /// installer's `~/.claude/local` location is checked first because it is
    /// the one most likely to be current.
    public static let defaultSearchPaths: [String] = [
        "\(NSHomeDirectory())/.claude/local/claude",
        "\(NSHomeDirectory())/.local/bin/claude",
        "/opt/homebrew/bin/claude",
        "/usr/local/bin/claude",
        "/usr/bin/claude",
    ]

    private let executableURL: URL?
    private let arguments: [String]
    private let timeout: Duration
    private let runner: ProcessRunning

    public init(
        executableURL: URL? = nil,
        arguments: [String] = ["-p", "/usage"],
        timeout: Duration = .seconds(30)
    ) {
        self.init(executableURL: executableURL, arguments: arguments, timeout: timeout, runner: SubprocessRunner())
    }

    /// Injectable runner so the client's error mapping can be tested without
    /// executing anything.
    init(executableURL: URL?, arguments: [String], timeout: Duration, runner: ProcessRunning) {
        self.executableURL = executableURL
        self.arguments = arguments
        self.timeout = timeout
        self.runner = runner
    }

    public func fetchUsage() async throws -> ClaudeCodeUsageReading {
        guard let executable = executableURL ?? Self.locateExecutable() else {
            throw UsageRepositoryError.unavailable
        }

        let output = try await runner.run(executable: executable, arguments: arguments, timeout: timeout)
        return try ClaudeUsageTextParser.parse(output)
    }

    /// First existing, executable candidate from the search paths.
    public static func locateExecutable() -> URL? {
        let fileManager = FileManager.default
        for path in defaultSearchPaths where fileManager.isExecutableFile(atPath: path) {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
}

/// Seam over process execution, so `ClaudeCodeCLIUsageClient` is testable.
protocol ProcessRunning: Sendable {
    func run(executable: URL, arguments: [String], timeout: Duration) async throws -> String
}

/// Runs the command with its stdout piped back, failing rather than hanging
/// if the command never exits.
struct SubprocessRunner: ProcessRunning {
    func run(executable: URL, arguments: [String], timeout: Duration) async throws -> String {
        let process = Process()
        process.executableURL = executable
        process.arguments = arguments

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        // A login shell's PATH is not inherited by a GUI app; give the CLI a
        // usable one so anything it shells out to resolves.
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = [
            environment["PATH"],
            "/opt/homebrew/bin",
            "/usr/local/bin",
            "/usr/bin",
            "/bin",
        ]
        .compactMap { $0 }
        .joined(separator: ":")
        process.environment = environment

        do {
            try process.run()
        } catch {
            throw UsageRepositoryError.unavailable
        }

        let watchdog = Task {
            try await Task.sleep(for: timeout)
            if process.isRunning { process.terminate() }
        }
        defer { watchdog.cancel() }

        // Read before waiting: a full pipe buffer would otherwise deadlock a
        // command that outproduces the 64KB pipe capacity.
        let data = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let message = String(data: errorData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            throw UsageRepositoryError.malformedResponse(
                "`claude \(arguments.joined(separator: " "))` exited with status \(process.terminationStatus)"
                    + (message.isEmpty ? "" : ": \(message)")
            )
        }

        return String(data: data, encoding: .utf8) ?? ""
    }
}
