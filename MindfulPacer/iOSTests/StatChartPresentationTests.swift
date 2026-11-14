import XCTest
import SwiftUI
@testable import iOS

@MainActor
final class StatChartPresentationTests: XCTestCase {
    func testSingleHeartRateReadingIsVisible() async throws {
        let image = try await render(entries: [sample(offset: 3_600)], style: .area(),
                                     name: "Heart rate with one reading")
        XCTAssertGreaterThan(try pinkPixelCount(in: image), 20,
                             "A reading must draw a visible mark even when there is no second point to connect.")
    }

    func testSingleStepsReadingIsVisible() async throws {
        let image = try await render(entries: [sample(offset: 3_600)], style: .line(),
                                     name: "Steps with one reading")
        XCTAssertGreaterThan(try pinkPixelCount(in: image), 20)
    }

    func testReadingAtWindowEdgeIsNotMovedOutsideByDateBucketing() async throws {
        let image = try await render(entries: [sample(offset: 7_199)], style: .area(),
                                     name: "Heart rate at the trailing edge")
        XCTAssertGreaterThan(try pinkPixelCount(in: image), 20)
    }

    func testSingleVisibleReadingWithEarlierHistoryIsVisible() async throws {
        let image = try await render(entries: [sample(offset: -3_600), sample(offset: 3_600)],
                                     style: .area(), name: "One visible reading with earlier history")
        XCTAssertGreaterThan(try pinkPixelCount(in: image), 20)
    }

    func testEmptyWindowWithHistoricalDataHasNoVisibleMarks() async throws {
        let image = try await render(entries: [sample(offset: -3_600)], style: .area(),
                                     name: "Empty period with data outside the window")
        XCTAssertEqual(try pinkPixelCount(in: image), 0)
    }

    private let start = Date(timeIntervalSince1970: 1_790_687_400)

    private func sample(offset: TimeInterval) -> ChartDataItem {
        let date = start.addingTimeInterval(offset)
        return .init(startDate: date, endDate: date, value: 85)
    }

    private func render(entries: [ChartDataItem], style: StatChartMarkStyle, name: String) async throws -> UIImage {
        let originalWindow = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: try XCTUnwrap(originalWindow?.windowScene))
        let configuration = StatChartConfiguration(
            markStyle: style, tintColor: .pink, chartHeight: 260, unitLabel: "bpm",
            periods: [.twoHours], defaultPeriod: .twoHours, visibleDomainLength: 7_200,
            xAxisDateFormat: "HH:mm", xAxisDateUnit: .minute, minimumValuePadding: 10,
            dateDomain: start.addingTimeInterval(-86_400)...start.addingTimeInterval(7_200),
            initialWindowStart: start
        )
        window.rootViewController = UIHostingController(rootView:
            StatChart(entries: entries, configuration: configuration)
                .padding(16)
                .background(Color.white)
                .environment(\.colorScheme, .light)
        )
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            originalWindow?.makeKeyAndVisible()
        }
        try await Task.sleep(for: .milliseconds(500))
        window.layoutIfNeeded()
        let image = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        let attachment = XCTAttachment(image: image)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        return image
    }

    /// Check the rendered marks, rather than merely asserting that the input array is nonempty.
    private func pinkPixelCount(in image: UIImage) throws -> Int {
        let image = try XCTUnwrap(image.cgImage)
        var pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let count = try pixels.withUnsafeMutableBytes { bytes -> Int in
            let context = try XCTUnwrap(CGContext(
                data: bytes.baseAddress, width: image.width, height: image.height,
                bitsPerComponent: 8, bytesPerRow: image.width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
            ))
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            let rgba = bytes.bindMemory(to: UInt8.self)
            return stride(from: 0, to: rgba.count, by: 4).reduce(0) { result, offset in
                result + (rgba[offset] > 180 && rgba[offset + 1] < 100
                          && rgba[offset + 2] > 40 && rgba[offset + 2] < 180 ? 1 : 0)
            }
        }
        return count
    }
}
