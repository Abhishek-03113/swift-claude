import XCTest
@testable import OrbitCore

/// The snapshot cache round-trips `UsageSnapshot` through JSON, so its
/// `Codable` conformance is load-bearing rather than incidental.
final class UsageSnapshotCodingTests: XCTestCase {
    func testSnapshotSurvivesAJSONRoundTrip() throws {
        let original = UsageFixtures.snapshot()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UsageSnapshot.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testProgressSurvivesWithFullPrecision() throws {
        let original = UsageFixtures.period(used: 1.5, limit: 2.25)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UsagePeriod.self, from: data)
        XCTAssertEqual(decoded.progress, 1.5 / 2.25, accuracy: 1e-9)
    }

    /// Decoding routes through the clamping initializer, so a corrupted or
    /// hand-edited cache cannot reintroduce an out-of-range fraction.
    func testDecodingClampsAnOutOfRangeFraction() throws {
        let json = """
        {"id":"session","type":"session","progress":4.2,"resetDate":0}
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(UsagePeriod.self, from: json)
        XCTAssertEqual(decoded.progress, 1, accuracy: 1e-9)
    }
}
