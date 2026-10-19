import ObjectiveC
import XCTest

/// One finger that goes down, moves along timed points and lifts at the end, started without waiting for it to
/// finish, so a test can look at the screen while the finger is still down (XCUITest's own drag is one straight line
/// and blocks until the finger lifts). XCTest's event synthesizer is private API; this is test code only and runs on
/// the simulator only.
@MainActor
struct HeldTouch {
    /// (point, seconds after touch-down) in screen points, in order; the finger lifts at the last one.
    let moves: [(point: CGPoint, at: TimeInterval)]

    /// Starts the touch and returns at once; `finish` waits for the lift.
    func start(_ test: XCTestCase) -> () -> Void {
        guard let first = moves.first, let record = Self.record(for: moves, first: first) else {
            XCTFail("The touch could not be built")
            return {}
        }
        let done = test.expectation(description: "touch lifted")
        let completion: @convention(block) (Bool, Error?) -> Void = { _, _ in done.fulfill() }
        typealias Send = @convention(c) (AnyObject, Selector, AnyObject, @convention(block) (Bool, Error?) -> Void)
            -> Void
        let synthesizer = XCUIDevice.shared.value(forKey: "eventSynthesizer") as AnyObject
        let selector = NSSelectorFromString("synthesizeEvent:completion:")
        guard let object = synthesizer as? NSObject else { XCTFail("No event synthesizer"); return {} }
        let send = unsafeBitCast(object.method(for: selector), to: Send.self)
        send(object, selector, record, completion)
        return { test.wait(for: [done], timeout: (moves.last?.at ?? 0) + 10) }
    }

    private static func record(
        for moves: [(point: CGPoint, at: TimeInterval)],
        first: (point: CGPoint, at: TimeInterval)
    )
        -> AnyObject?
    {
        guard let pathClass = NSClassFromString("XCPointerEventPath") as? NSObject.Type,
              let recordClass = NSClassFromString("XCSynthesizedEventRecord") as? NSObject.Type else { return nil }
        // path = [[XCPointerEventPath alloc] initForTouchAtPoint:first offset:0]
        typealias InitPath = @convention(c) (AnyObject, Selector, CGPoint, Double) -> AnyObject
        typealias Move = @convention(c) (AnyObject, Selector, CGPoint, Double) -> Void
        typealias Lift = @convention(c) (AnyObject, Selector, Double) -> Void
        typealias InitRecord = @convention(c) (AnyObject, Selector, NSString, Int) -> AnyObject
        typealias Add = @convention(c) (AnyObject, Selector, AnyObject) -> Void
        let alloc = NSSelectorFromString("alloc")
        guard let pathObject = pathClass.perform(alloc)?.takeUnretainedValue() as? NSObject,
              let recordObject = recordClass.perform(alloc)?.takeUnretainedValue() as? NSObject else { return nil }
        let initPath = NSSelectorFromString("initForTouchAtPoint:offset:")
        let path = unsafeBitCast(pathObject.method(for: initPath), to: InitPath.self)(
            pathObject,
            initPath,
            first.point,
            0
        )
        guard let pathNS = path as? NSObject else { return nil }
        let move = NSSelectorFromString("moveToPoint:atOffset:")
        let moveIMP = unsafeBitCast(pathNS.method(for: move), to: Move.self)
        for step in moves.dropFirst() {
            moveIMP(pathNS, move, step.point, step.at)
        }
        let lift = NSSelectorFromString("liftUpAtOffset:")
        unsafeBitCast(pathNS.method(for: lift), to: Lift.self)(pathNS, lift, (moves.last?.at ?? 0) + 0.05)
        let initRecord = NSSelectorFromString("initWithName:interfaceOrientation:")
        let made = unsafeBitCast(recordObject.method(for: initRecord), to: InitRecord.self)(
            recordObject, initRecord, "HeldTouch", 1
        )
        guard let recordNS = made as? NSObject else { return nil }
        let add = NSSelectorFromString("addPointerEventPath:")
        unsafeBitCast(recordNS.method(for: add), to: Add.self)(recordNS, add, pathNS)
        return recordNS
    }
}
