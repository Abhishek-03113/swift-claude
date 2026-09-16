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

    func testDurationsSurviveWithSubSecondPrecision() throws {
        let original = UsageFixtures.period(used: 1.5, limit: 2.25)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(UsagePeriod.self, from: data)
        XCTAssertEqual(decoded.used.secondsDouble, 1.5, accuracy: 1e-9)
        XCTAssertEqual(decoded.limit.secondsDouble, 2.25, accuracy: 1e-9)
    }
}
