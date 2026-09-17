import XCTest
import OrbitCore
@testable import OrbitProviders

private struct StubTokenStore: ClaudeCodeTokenStoring {
    let result: Result<String, UsageRepositoryError>
    func accessToken() throws -> String { try result.get() }
}

/// Intercepts requests made through a `URLSession` configured with this
/// protocol registered, so the API client's request/response handling is
/// tested without touching the network.
private final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler: ((URLRequest) -> (Int, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        let (status, data) = handler(request)
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

final class ClaudeCodeAPIUsageClientTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_000_000)

    /// The actual payload `/api/oauth/usage` returns for a subscription
    /// account, captured from a live call. Full-shape rather than trimmed,
    /// so the decoder's tolerance of unmodeled/unstable fields (the many
    /// null internal-codename keys) is exercised for real.
    private static let livePayload = #"""
    {
      "five_hour": {"utilization": 89.0, "resets_at": "2026-09-17T15:10:00.191106+00:00", "limit_dollars": null, "used_dollars": null, "remaining_dollars": null, "locked_reason": null},
      "seven_day": {"utilization": 35.0, "resets_at": "2026-09-20T20:00:00.191128+00:00", "limit_dollars": null, "used_dollars": null, "remaining_dollars": null, "locked_reason": null},
      "seven_day_oauth_apps": null,
      "seven_day_opus": null,
      "seven_day_sonnet": null,
      "seven_day_cowork": null,
      "seven_day_omelette": null,
      "tangelo": null,
      "iguana_necktie": null,
      "omelette_promotional": null,
      "nimbus_quill": {"utilization": 0.0, "resets_at": null, "limit_dollars": null, "used_dollars": null, "remaining_dollars": null, "locked_reason": null},
      "cinder_cove": null,
      "copper_kite": null,
      "harbor_lantern": null,
      "amber_ladder": null,
      "juniper_tide": null,
      "cedar_ember": null,
      "amber_gauge": null,
      "extra_usage": {
        "is_enabled": false,
        "monthly_limit": 0,
        "used_credits": 0.0,
        "utilization": null,
        "currency": "USD",
        "decimal_places": 2,
        "disabled_reason": "org_level_disabled_until",
        "user_disabled": false,
        "spend_limit_reached": false,
        "credits_ever_enabled": true,
        "daily": null,
        "weekly": null
      },
      "limits": [
        {"kind": "session", "group": "session", "percent": 89, "severity": "warning", "resets_at": "2026-09-17T15:10:00.191106+00:00", "scope": null, "is_active": true},
        {"kind": "weekly_all", "group": "weekly", "percent": 35, "severity": "normal", "resets_at": "2026-09-20T20:00:00.191128+00:00", "scope": null, "is_active": false}
      ],
      "spend": {
        "used": {"amount_minor": 0, "currency": "USD", "exponent": 2},
        "limit": {"amount_minor": 0, "currency": "USD", "exponent": 2},
        "percent": 0,
        "severity": "normal",
        "enabled": false,
        "disabled_reason": "org_level_disabled_until",
        "cap": {"money": null, "credits": {"amount_minor": 0, "exponent": 2}},
        "balance": null,
        "auto_reload": null,
        "disclaimer": "Usage credits cover you when you hit your plan limits.",
        "can_purchase_credits": false,
        "can_toggle": false
      },
      "member_dashboard_available": false,
      "seven_day_breakdown": {
        "as_of": "2026-09-17T13:28:09.230452+00:00",
        "window_started_at": "2026-09-13T20:00:00.191128+00:00",
        "rows": [
          {"key": "claude_code", "display_name": "Claude Code", "percent": 89},
          {"key": "chat", "display_name": "Chats", "percent": 1},
          {"key": "cowork", "display_name": "Cowork", "percent": 4},
          {"key": "other", "display_name": "Other", "percent": 6}
        ]
      }
    }
    """#.data(using: .utf8)!

    private func client(status: Int = 200, data: Data = livePayload, token: Result<String, UsageRepositoryError> = .success("test-token")) -> ClaudeCodeAPIUsageClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        StubURLProtocol.handler = { _ in (status, data) }
        return ClaudeCodeAPIUsageClient(
            tokenStore: StubTokenStore(result: token),
            session: URLSession(configuration: configuration),
            now: { [now] in now }
        )
    }

    override func tearDown() {
        StubURLProtocol.handler = nil
        super.tearDown()
    }

    func testParsesFiveHourAndSevenDayIntoSessionAndWeeklyPeriods() async throws {
        let reading = try await client().fetchUsage()

        XCTAssertEqual(reading.periods.first { $0.type == .session }?.progress ?? 0, 0.89, accuracy: 1e-9)
        XCTAssertEqual(reading.periods.first { $0.type == .weekly }?.progress ?? 0, 0.35, accuracy: 1e-9)
    }

    func testParsesFractionalSecondResetTimestamps() async throws {
        let reading = try await client().fetchUsage()
        let sessionReset = reading.periods.first { $0.type == .session }?.resetDate

        let expected = ISO8601DateFormatter()
        expected.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        XCTAssertEqual(sessionReset, expected.date(from: "2026-09-17T15:10:00.191106+00:00"))
    }

    func testCarriesSevenDayBreakdownAndExtraUsageAsAnalytics() async throws {
        let reading = try await client().fetchUsage()

        let analytics = try XCTUnwrap(reading.analytics)
        XCTAssertEqual(analytics.sevenDayBreakdown.map(\.id), ["claude_code", "chat", "cowork", "other"])
        XCTAssertEqual(analytics.sevenDayBreakdown.first?.percent, 89)
        XCTAssertEqual(analytics.extraUsage?.isEnabled, false)
        XCTAssertEqual(analytics.extraUsage?.currency, "USD")
    }

    func testMissingKeychainTokenReportsNotAuthenticated() async {
        let client = client(token: .failure(.notAuthenticated))
        do {
            _ = try await client.fetchUsage()
            XCTFail("expected fetchUsage() to throw")
        } catch {
            XCTAssertEqual(error as? UsageRepositoryError, .notAuthenticated)
        }
    }

    func testUnauthorizedResponseReportsNotAuthenticated() async {
        let client = client(status: 401, data: Data())
        do {
            _ = try await client.fetchUsage()
            XCTFail("expected fetchUsage() to throw")
        } catch {
            XCTAssertEqual(error as? UsageRepositoryError, .notAuthenticated)
        }
    }

    func testMalformedJSONReportsMalformedResponse() async {
        let client = client(data: #"{"nonsense": true}"#.data(using: .utf8)!)
        do {
            _ = try await client.fetchUsage()
            XCTFail("expected fetchUsage() to throw")
        } catch {
            guard case UsageRepositoryError.malformedResponse = error else {
                return XCTFail("expected malformedResponse, got \(error)")
            }
        }
    }
}
