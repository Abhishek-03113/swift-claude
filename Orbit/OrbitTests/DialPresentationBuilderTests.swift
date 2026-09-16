import XCTest

final class DialPresentationBuilderTests: XCTestCase {
    func testSessionSelectedMakesInnerRingDominant() {
        let snapshot = MockUsageProvider.snapshot()
        let presentation = DialPresentationBuilder.build(snapshot: snapshot, selected: .session)!

        XCTAssertTrue(presentation.inner.isSelected)
        XCTAssertFalse(presentation.outer.isSelected)
        XCTAssertEqual(presentation.inner.arcOpacity, DialMetrics.innerArcOpacitySelected)
        XCTAssertEqual(presentation.outer.arcOpacity, DialMetrics.outerArcOpacityUnselected)
        XCTAssertEqual(presentation.focusPeriodLabel, "SESSION")
    }

    func testWeeklySelectedMakesOuterRingDominant() {
        let snapshot = MockUsageProvider.snapshot()
        let presentation = DialPresentationBuilder.build(snapshot: snapshot, selected: .weekly)!

        XCTAssertTrue(presentation.outer.isSelected)
        XCTAssertFalse(presentation.inner.isSelected)
        XCTAssertEqual(presentation.outer.arcOpacity, DialMetrics.outerArcOpacitySelected)
        XCTAssertEqual(presentation.inner.arcOpacity, DialMetrics.innerArcOpacityUnselected)
        XCTAssertEqual(presentation.focusPeriodLabel, "WEEKLY")
    }

    func testZeroPercentUsageProducesZeroProgress() {
        let snapshot = MockUsageProvider.snapshot(sessionUsedFraction: 0, weeklyUsedFraction: 0)
        let presentation = DialPresentationBuilder.build(snapshot: snapshot, selected: .session)!
        XCTAssertEqual(presentation.inner.progress, 0, accuracy: 1e-9)
    }

    func testFullUsageProducesFullProgress() {
        let snapshot = MockUsageProvider.snapshot(sessionUsedFraction: 1, weeklyUsedFraction: 1)
        let presentation = DialPresentationBuilder.build(snapshot: snapshot, selected: .session)!
        XCTAssertEqual(presentation.inner.progress, 1, accuracy: 1e-9)
    }

    func testFiftyPercentUsage() {
        let snapshot = MockUsageProvider.snapshot(sessionUsedFraction: 0.5, weeklyUsedFraction: 0.5)
        let presentation = DialPresentationBuilder.build(snapshot: snapshot, selected: .session)!
        XCTAssertEqual(presentation.inner.progress, 0.5, accuracy: 1e-9)
    }

    func testStaleStateSurfacesUpdatedAgoText() {
        let now = Date()
        let snapshot = MockUsageProvider.snapshot(now: now.addingTimeInterval(-900))
        let presentation = DialPresentationBuilder.build(snapshot: snapshot, selected: .session, now: now, staleness: .stale(snapshot))!
        XCTAssertEqual(presentation.lastUpdatedText, "updated 15m ago")
    }

    func testMissingRequiredPeriodReturnsNil() {
        let onlySession = UsageSnapshot(
            provider: .claudeCode,
            periods: [UsagePeriod(id: "session", type: .session, used: .seconds(0), limit: .seconds(100), resetDate: .now)],
            lastUpdated: .now
        )
        XCTAssertNil(DialPresentationBuilder.build(snapshot: onlySession, selected: .session))
    }
}
