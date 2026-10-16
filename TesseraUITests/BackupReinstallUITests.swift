import XCTest

/// Restore-walk 3: on a fresh install (nothing done yet) Backups says a restore is possible.
@MainActor
final class BackupReinstallUITests: SimulatorOnlyTestCase {
    func testFreshInstallOffersRestore() {
        let app = XCUIApplication()
        app.launchArguments = ["-resetDemo", "-openLink", "review"]
        app.launch()
        let backups = app.buttons.matching(NSPredicate(format: "label ==[c] %@", "Backups")).firstMatch
        XCTAssertTrue(backups.waitForExistence(timeout: 15))
        app.swipeUp()
        app.swipeUp()
        backups.tap()
        XCTAssertTrue(app.staticTexts["Reinstalled? Restore brings back your copy from iCloud Drive."]
            .waitForExistence(timeout: 5))
        sleep(2)
    }
}
