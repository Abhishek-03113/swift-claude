import XCTest
import OrbitCore
@testable import OrbitPresentation

final class SelectedPeriodStoreTests: XCTestCase {
    private func freshStore() -> SelectedPeriodStore {
        SelectedPeriodStore(store: AppGroupStore(suiteName: "orbit.tests.\(UUID().uuidString)"))
    }

    func testDefaultsToSessionBeforeAnythingIsSaved() {
        XCTAssertEqual(freshStore().load(), .session)
    }

    func testSavedSelectionRoundTrips() {
        let store = freshStore()
        for period in SelectedUsagePeriod.allCases {
            store.save(period)
            XCTAssertEqual(store.load(), period)
        }
    }
}
