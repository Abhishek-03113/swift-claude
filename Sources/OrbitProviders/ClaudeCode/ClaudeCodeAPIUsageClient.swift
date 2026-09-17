import Foundation
import OrbitCore

/// Reads usage directly from the same endpoint Claude Code's own `/usage`
/// command calls, using the CLI's own OAuth token from Keychain
/// (`ClaudeCodeTokenStoring`). No subprocess, and a stable JSON contract
/// instead of parsed CLI text — see `ClaudeCodeCLIUsageClient` for the
/// fallback this replaces as the primary source.
public struct ClaudeCodeAPIUsageClient: ClaudeCodeUsageClient {
    private static let endpoint = URL(string: "https://api.anthropic.com/api/oauth/usage")!

    private let tokenStore: ClaudeCodeTokenStoring
    private let session: URLSession
    private let now: @Sendable () -> Date

    public init(
        tokenStore: ClaudeCodeTokenStoring = ClaudeCodeKeychainTokenStore(),
        session: URLSession = .shared
    ) {
        self.init(tokenStore: tokenStore, session: session, now: { .now })
    }

    init(tokenStore: ClaudeCodeTokenStoring, session: URLSession, now: @escaping @Sendable () -> Date) {
        self.tokenStore = tokenStore
        self.session = session
        self.now = now
    }

    public func fetchUsage() async throws -> ClaudeCodeUsageReading {
        let token = try tokenStore.accessToken()

        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw UsageRepositoryError.unavailable
        }

        guard let http = response as? HTTPURLResponse else {
            throw UsageRepositoryError.unavailable
        }

        guard http.statusCode == 200 else {
            if http.statusCode == 401 || http.statusCode == 403 {
                throw UsageRepositoryError.notAuthenticated
            }
            throw UsageRepositoryError.malformedResponse("GET /api/oauth/usage returned status \(http.statusCode)")
        }

        let payload: UsagePayload
        do {
            payload = try JSONDecoder.claudeCodeAPI.decode(UsagePayload.self, from: data)
        } catch {
            throw UsageRepositoryError.malformedResponse("Could not decode /api/oauth/usage response: \(error)")
        }

        return try payload.toReading(generatedAt: now())
    }
}

// MARK: - Response model

/// Mirrors `/api/oauth/usage`'s JSON. Deliberately permissive: most top-level
/// fields are internal codenames Anthropic may rename or add to freely, so
/// only the fields this client actually uses are modeled, and every one of
/// them is optional except where its absence makes the whole response
/// meaningless.
private struct UsagePayload: Decodable {
    struct Window: Decodable {
        let utilization: Double?
        let resetsAt: Date?
    }

    struct ExtraUsage: Decodable {
        let isEnabled: Bool
        let monthlyLimit: Double
        let usedCredits: Double
        let utilization: Double?
        let currency: String
    }

    struct SevenDayBreakdown: Decodable {
        struct Row: Decodable {
            let key: String
            let displayName: String
            let percent: Double
        }

        let rows: [Row]
    }

    let fiveHour: Window?
    let sevenDay: Window?
    let extraUsage: ExtraUsage?
    let sevenDayBreakdown: SevenDayBreakdown?

    func toReading(generatedAt: Date) throws -> ClaudeCodeUsageReading {
        guard let fiveHour, let fiveHourUtilization = fiveHour.utilization, let fiveHourReset = fiveHour.resetsAt else {
            throw UsageRepositoryError.malformedResponse("/api/oauth/usage response is missing five_hour utilization/resets_at")
        }
        guard let sevenDay, let sevenDayUtilization = sevenDay.utilization, let sevenDayReset = sevenDay.resetsAt else {
            throw UsageRepositoryError.malformedResponse("/api/oauth/usage response is missing seven_day utilization/resets_at")
        }

        let periods = [
            UsagePeriod(id: "session", type: .session, usedFraction: fiveHourUtilization / 100, resetDate: fiveHourReset),
            UsagePeriod(id: "weekly", type: .weekly, usedFraction: sevenDayUtilization / 100, resetDate: sevenDayReset),
        ]

        let analytics = ClaudeUsageAnalytics(
            extraUsage: extraUsage.map {
                ClaudeUsageAnalytics.ExtraUsage(
                    isEnabled: $0.isEnabled,
                    monthlyLimit: $0.monthlyLimit,
                    usedCredits: $0.usedCredits,
                    utilization: $0.utilization,
                    currency: $0.currency
                )
            },
            sevenDayBreakdown: (sevenDayBreakdown?.rows ?? []).map {
                ClaudeUsageAnalytics.SurfaceShare(id: $0.key, displayName: $0.displayName, percent: $0.percent)
            },
            generatedAt: generatedAt
        )

        return ClaudeCodeUsageReading(periods: periods, generatedAt: generatedAt, analytics: analytics)
    }
}

private extension JSONDecoder {
    /// `resets_at` comes back as `2026-09-17T15:10:00.191106+00:00` —
    /// fractional-second ISO 8601, which `.iso8601` alone rejects.
    static let claudeCodeAPI: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let text = try container.decode(String.self)
            if let date = formatter.date(from: text) ?? fallback.date(from: text) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date format: \(text)")
        }
        return decoder
    }()
}
