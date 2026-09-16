import XCTest
@testable import OrbitCore

final class UsageColorRampTests: XCTestCase {
    func testZeroUsageIsGreen() {
        let color = UsageColorRamp.components(forUsagePercent: 0)
        XCTAssertEqual(color.red, 62 / 255, accuracy: 1e-6)
        XCTAssertEqual(color.green, 226 / 255, accuracy: 1e-6)
        XCTAssertEqual(color.blue, 149 / 255, accuracy: 1e-6)
    }

    func testFullUsageIsRed() {
        let color = UsageColorRamp.components(forUsagePercent: 100)
        XCTAssertEqual(color.red, 255 / 255, accuracy: 1e-6)
        XCTAssertEqual(color.green, 82 / 255, accuracy: 1e-6)
        XCTAssertEqual(color.blue, 78 / 255, accuracy: 1e-6)
    }

    func testValuesBelowZeroClampToTheZeroStop() {
        assertEqualColors(
            UsageColorRamp.components(forUsagePercent: -50),
            UsageColorRamp.components(forUsagePercent: 0)
        )
    }

    func testValuesAboveOneHundredClampToTheFinalStop() {
        assertEqualColors(
            UsageColorRamp.components(forUsagePercent: 250),
            UsageColorRamp.components(forUsagePercent: 100)
        )
    }

    func testMidpointInterpolatesBetweenNeighboringStops() {
        // 10 sits halfway between the 0 and 20 stops.
        let mid = UsageColorRamp.components(forUsagePercent: 10)
        let low = UsageColorRamp.components(forUsagePercent: 0)
        let high = UsageColorRamp.components(forUsagePercent: 20)
        XCTAssertEqual(mid.red, (low.red + high.red) / 2, accuracy: 1e-6)
        XCTAssertEqual(mid.green, (low.green + high.green) / 2, accuracy: 1e-6)
        XCTAssertEqual(mid.blue, (low.blue + high.blue) / 2, accuracy: 1e-6)
    }

    func testEveryStopIsExactlyReproducedAtItsOwnPercent() {
        for stop in UsageColorRamp.stops {
            let color = UsageColorRamp.components(forUsagePercent: stop.at)
            XCTAssertEqual(color.red, stop.rgb.red / 255, accuracy: 1e-6, "red at \(stop.at)")
            XCTAssertEqual(color.green, stop.rgb.green / 255, accuracy: 1e-6, "green at \(stop.at)")
            XCTAssertEqual(color.blue, stop.rgb.blue / 255, accuracy: 1e-6, "blue at \(stop.at)")
        }
    }

    private func assertEqualColors(
        _ lhs: (red: Double, green: Double, blue: Double),
        _ rhs: (red: Double, green: Double, blue: Double),
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(lhs.red, rhs.red, accuracy: 1e-9, file: file, line: line)
        XCTAssertEqual(lhs.green, rhs.green, accuracy: 1e-9, file: file, line: line)
        XCTAssertEqual(lhs.blue, rhs.blue, accuracy: 1e-9, file: file, line: line)
    }
}
