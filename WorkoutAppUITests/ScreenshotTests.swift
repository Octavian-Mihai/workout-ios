import XCTest

final class ScreenshotTests: XCTestCase {
    private let screenshotDirectory = "/Users/user_octa/Desktop/DESKTOP/PROJECTS/cursor/workout_ios/docs/screenshots"

    override func setUp() {
        continueAfterFailure = true
    }

    func testCaptureScreenshots() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-UITEST_SCREENSHOTS")
        app.launchEnvironment["UITEST_SCREENSHOTS"] = "1"
        app.launch()

        sleep(2)
        configureAppearanceForScreenshots(in: app)

        saveScreenshot(named: "home", in: app)

        tapTab("Workout", in: app)
        saveScreenshot(named: "workout", in: app)

        tapTab("Running", in: app)
        saveScreenshot(named: "running", in: app)

        tapTab("Info", in: app)
        saveScreenshot(named: "info", in: app)

        tapTab("Settings", in: app)
        saveScreenshot(named: "settings", in: app)

        tapTab("Home", in: app)
        let startEmpty = app.buttons["Start empty workout"]
        if startEmpty.waitForExistence(timeout: 3) {
            startEmpty.tap()
            sleep(1)
            saveScreenshot(named: "live-workout", in: app)
        }
    }

    private func configureAppearanceForScreenshots(in app: XCUIApplication) {
        tapTab("Settings", in: app)
        let dark = app.buttons["Dark"]
        if dark.waitForExistence(timeout: 2) {
            dark.tap()
        }
        let red = app.buttons["Red"]
        if red.waitForExistence(timeout: 2) {
            red.tap()
        }
        sleep(1)
        tapTab("Home", in: app)
    }

    private func tapTab(_ label: String, in app: XCUIApplication) {
        app.tabBars.buttons[label].tap()
        sleep(1)
    }

    private func saveScreenshot(named name: String, in app: XCUIApplication) {
        let screenshot = app.windows.firstMatch.screenshot()
        let data = screenshot.pngRepresentation
        let directory = URL(fileURLWithPath: screenshotDirectory, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let fileURL = directory.appendingPathComponent("\(name).png")
        try? data.write(to: fileURL)
    }
}
