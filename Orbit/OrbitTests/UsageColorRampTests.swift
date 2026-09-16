import XCTest

final class UsageColorRampTests: XCTestCase {
    func testZeroUsageIsGreen() {
        let c = UsageColorRamp.components(forUsagePercent: 0)
        XCTAssertEqual(c.red, 62 / 255, accuracy: 1e-6)
        XCTAssertEqual(c.green, 226 / 255, accuracy: 1e-6)
        XCTAssertEqual(c.blue, 149 / 255, accuracy: 1e-6)
    }

    func testFullUsageIsRed() {
        let c = UsageColorRamp.components(forUsagePercent: 100)
        XCTAssertEqual(c.red, 255 / 255, accuracy: 1e-6)
        XCTAssertEqual(c.green, 82 / 255, accuracy: 1e-6)
        XCTAssertEqual(c.blue, 78 / 255, accuracy: 1e-6)
    }

    func testValuesBelowZeroClampToTheZeroStop() {
        let below = UsageColorRamp.components(forUsagePercent: -50)
        let zero = UsageColorRamp.components(forUsagePercent: 0)
        XCTAssertEqual(below.red, zero.red, accuracy: 1e-9)
        XCTAssertEqual(below.green, zero.green, accuracy: 1e-9)
        XCTAssertEqual(below.blue, zero.blue, accuracy: 1e-9)
    }

    func testValuesAboveOneHundredClampToTheFinalStop() {
        let above = UsageColorRamp.components(forUsagePercent: 250)
        let full = UsageColorRamp.components(forUsagePercent: 100)
        XCTAssertEqual(above.red, full.red, accuracy: 1e-9)
        XCTAssertEqual(above.green, full.green, accuracy: 1e-9)
        XCTAssertEqual(above.blue, full.blue, accuracy: 1e-9)
    }

    func testMidpointInterpolatesBetweenNeighboringStops() {
        // 10 sits halfway between the 0 and 20 stops.
        let c = UsageColorRamp.components(forUsagePercent: 10)
        let a = UsageColorRamp.components(forUsagePercent: 0)
        let b = UsageColorRamp.components(forUsagePercent: 20)
        XCTAssertEqual(c.red, (a.red + b.red) / 2, accuracy: 1e-6)
    }
}
