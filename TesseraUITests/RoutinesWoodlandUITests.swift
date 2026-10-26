import XCTest

/// The Routines woodland landing (248, landing contract §14): a tap on a plant names it in the caption, the dial turns
/// to a tapped neighbour, and the foot carries "Plant". Launched straight onto the landing with `-routinesLanding`.
@MainActor
final class RoutinesWoodlandUITests: SimulatorOnlyTestCase {
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-routinesLanding", "-demo", "-demoTime", "18:10"]
        app.launch()
        XCTAssertTrue(
            app.descendants(matching: .any)["Watch"].firstMatch.waitForExistence(timeout: 20),
            "The landing is up"
        )
        return app
    }

    func testFootCarriesPlantAndTheDialTurnsToATappedNeighbour() {
        let app = launch()
        let foot = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Plant'")).firstMatch
        XCTAssertTrue(foot.exists, "The foot's verb is Plant, over its object")
        let body = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Body'")).firstMatch
        XCTAssertTrue(body.waitForExistence(timeout: 5), "Body is a neighbour of Today")
        body.tap()
        let selected = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Body' AND selected == true"))
        XCTAssertTrue(selected.firstMatch.waitForExistence(timeout: 3), "The dial turned to Body")
    }

    func testTappingAPlantNamesItInTheCaption() {
        let app = launch()
        let plant = app.descendants(matching: .any).matching(identifier: "woodland.plant").firstMatch
        XCTAssertTrue(plant.waitForExistence(timeout: 5), "The woodland has a plant")
        let name = plant.label.components(separatedBy: ",").first ?? ""
        plant.tap()
        let caption = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@ AND label CONTAINS 'Tap again'",
                                                           name))
        XCTAssertTrue(caption.firstMatch.waitForExistence(timeout: 3), "The caption names \(name)")
    }
}
