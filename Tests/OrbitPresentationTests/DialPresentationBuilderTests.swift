import XCTest
import OrbitCore
import OrbitProviders
@testable import OrbitPresentation

final class DialPresentationBuilderTests: XCTestCase {
    private func build(
        sessionUsedFraction: Double = 0.32,
        weeklyUsedFraction: Double = 0.59,
        selected: SelectedUsagePeriod = .session
    ) throws -> DialPresentation {
        let snapshot = MockUsageProvider.snapshot(
            sessionUsedFraction: sessionUsedFraction,
            weeklyUsedFraction: weeklyUsedFraction
        )
        return try XCTUnwrap(DialPresentationBuilder.build(snapshot: snapshot, selected: selected))
    }

    func testSessionSelectedMakesInnerRingDominant() throws {
        let presentation = try build(selected: .session)

        XCTAssertTrue(presentation.inner.isSelected)
        XCTAssertFalse(presentation.outer.isSelected)
        XCTAssertEqual(presentation.inner.arcOpacity, DialMetrics.innerArcOpacitySelected)
        XCTAssertEqual(presentation.inner.trackOpacity, DialMetrics.innerTrackOpacitySelected)
        XCTAssertEqual(presentation.inner.glowRadiusAtReferenceSize, DialMetrics.innerGlowSelected)
        XCTAssertEqual(presentation.outer.arcOpacity, DialMetrics.outerArcOpacityUnselected)
        XCTAssertEqual(presentation.focusPeriodLabel, "SESSION")
        XCTAssertEqual(presentation.secondaryPeriodLabel, "WEEKLY")
    }

    func testWeeklySelectedMakesOuterRingDominant() throws {
        let presentation = try build(selected: .weekly)

        XCTAssertTrue(presentation.outer.isSelected)
        XCTAssertFalse(presentation.inner.isSelected)
        XCTAssertEqual(presentation.outer.arcOpacity, DialMetrics.outerArcOpacitySelected)
        XCTAssertEqual(presentation.outer.trackOpacity, DialMetrics.outerTrackOpacitySelected)
        XCTAssertEqual(presentation.outer.glowRadiusAtReferenceSize, DialMetrics.outerGlowSelected)
        XCTAssertEqual(presentation.inner.arcOpacity, DialMetrics.innerArcOpacityUnselected)
        XCTAssertEqual(presentation.focusPeriodLabel, "WEEKLY")
        XCTAssertEqual(presentation.secondaryPeriodLabel, "SESSION")
    }

    func testRingProgressTracksUsageFraction() throws {
        for fraction in [0.0, 0.5, 1.0] {
            let presentation = try build(sessionUsedFraction: fraction)
            XCTAssertEqual(presentation.inner.progress, fraction, accuracy: 1e-9)
        }
    }

    /// The center reads the *focused* period: its remaining percentage, and
    /// the time until that window resets (not quota re-expressed as time).
    func testFocusedPeriodDrivesTheCenterValue() throws {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let snapshot = UsageSnapshot(
            provider: .claudeCode,
            periods: [
                UsagePeriod(id: "session", type: .session, usedFraction: 0.25, resetDate: now.addingTimeInterval(3600)),
                UsagePeriod(id: "weekly", type: .weekly, usedFraction: 0.60, resetDate: now.addingTimeInterval(4 * 86400)),
            ],
            lastUpdated: now
        )

        let onSession = try XCTUnwrap(DialPresentationBuilder.build(snapshot: snapshot, selected: .session, now: now))
        XCTAssertEqual(onSession.focusRemainingPercent, 75)
        XCTAssertEqual(onSession.focusTimeUntilReset.secondsDouble, 3600, accuracy: 1e-6)

        let onWeekly = try XCTUnwrap(DialPresentationBuilder.build(snapshot: snapshot, selected: .weekly, now: now))
        XCTAssertEqual(onWeekly.focusRemainingPercent, 40)
        XCTAssertEqual(onWeekly.focusTimeUntilReset.secondsDouble, 4 * 86400, accuracy: 1e-6)
    }

    func testFreshSnapshotHasNoUpdatedAgoText() throws {
        XCTAssertNil(try build().lastUpdatedText)
    }

    func testStaleStateSurfacesUpdatedAgoText() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let snapshot = MockUsageProvider.snapshot(now: now.addingTimeInterval(-900))
        let presentation = try XCTUnwrap(
            DialPresentationBuilder.build(snapshot: snapshot, selected: .session, now: now, staleness: .stale(snapshot))
        )
        XCTAssertEqual(presentation.lastUpdatedText, "updated 15m ago")
    }

    func testAccessibilityLabelsNameTheProviderAndBothWindows() throws {
        let presentation = try build()
        XCTAssertTrue(presentation.inner.accessibilityLabel.contains("Claude Code session usage"))
        XCTAssertTrue(presentation.inner.accessibilityLabel.contains("5-hour limit"))
        XCTAssertTrue(presentation.outer.accessibilityLabel.contains("Claude Code weekly usage"))
        XCTAssertTrue(presentation.outer.accessibilityLabel.contains("weekly limit"))
    }

    func testMissingRequiredPeriodReturnsNil() {
        let sessionOnly = UsageSnapshot(
            provider: .claudeCode,
            periods: [
                UsagePeriod(id: "session", type: .session, used: .seconds(0), limit: .seconds(100), resetDate: .now),
            ],
            lastUpdated: .now
        )
        XCTAssertNil(DialPresentationBuilder.build(snapshot: sessionOnly, selected: .session))
    }
}
