import Foundation
@testable import TesseraTess
import Testing

/// H5: every call is held to the schema it was offered with before anything runs, and the line it gets back names
/// fields, never what the model wrote.
struct ToolInputCheckTests {
    let schema = Data(#"""
    {"type":"object","additionalProperties":false,"required":["title","count","kind","when","tags","done","depth"],
     "properties":{"title":{"type":"string"},"count":{"type":"integer"},"kind":{"type":"string","enum":["a","b"]},
     "when":{"type":["string","null"]},"tags":{"type":"array","items":{"type":"string"}},
     "done":{"type":"boolean"},"depth":{"type":["integer","null"],"enum":[1,2]}}}
    """#.utf8)

    func problem(_ json: String) -> String? {
        ToolInputCheck.problem(Data(json.utf8), schema: schema)
    }

    let fits = #"{"title":"Call mom","count":2,"kind":"a","when":null,"tags":["x"],"done":false,"depth":1}"#

    @Test func aCallThatFitsHasNoProblem() {
        #expect(problem(fits) == nil)
    }

    @Test func aNullableFieldMayBeNullOrLeftOut() {
        #expect(problem(#"{"title":"t","count":2,"kind":"a","tags":[],"done":true}"#) == nil)
        #expect(problem(#"{"title":"t","count":2,"kind":"a","when":null,"tags":[],"done":true,"depth":null}"#) == nil)
    }

    @Test(arguments: [
        (#"{"count":2,"kind":"a","tags":[],"done":true}"#, "\"title\""),
        (#"{"title":5,"count":2,"kind":"a","tags":[],"done":true}"#, "\"title\" should be text"),
        (#"{"title":"t","count":2.5,"kind":"a","tags":[],"done":true}"#, "\"count\" should be a whole number"),
        (#"{"title":"t","count":2,"kind":"c","tags":[],"done":true}"#, "\"kind\" should be one of a, b"),
        (#"{"title":"t","count":2,"kind":"a","tags":[3],"done":true}"#, "item 1 of \"tags\" should be text"),
        (#"{"title":"t","count":2,"kind":"a","tags":[],"done":1}"#, "\"done\" should be true or false"),
        (#"{"title":"t","count":true,"kind":"a","tags":[],"done":true}"#, "\"count\" should be a whole number"),
        (#"{"title":"t","count":2,"kind":"a","tags":[],"done":true,"depth":3}"#, "\"depth\" should be one of 1, 2"),
        (#"{"title":"t","count":2,"kind":"a","tags":[],"done":true,"extra":1}"#, "no field \"extra\""),
        (#"["title"]"#, "should be an object"),
    ])
    func aCallThatDoesNotFitSaysWhichField(json: String, says: String) throws {
        let line = try #require(problem(json))
        #expect(line.hasPrefix("Error: ") && line.contains(says), "\(line)")
    }

    @Test func theLineNeverEchoesAValue() throws {
        let json = #"{"title":"my secret words","count":"locker 4-27-19","kind":"a","tags":[],"done":true}"#
        let line = try #require(problem(json))
        #expect(!line.contains("secret") && !line.contains("4-27-19"))
    }

    @Test func unreadableArgumentsAreAProblemAndAnUnreadableSchemaChecksNothing() {
        #expect(problem(#"{"title":"#) == "Error: the arguments aren't readable JSON.")
        #expect(ToolInputCheck.problem(Data(#"{"a":1}"#.utf8), schema: Data("not json".utf8)) == nil)
    }

    @Test func anyOfTakesTheFirstFormThatFits() {
        let nullable = Data(#"{"anyOf":[{"type":"string","enum":["x","y"]},{"type":"null"}]}"#.utf8)
        #expect(ToolInputCheck.problem(Data("null".utf8), schema: nullable) == nil)
        #expect(ToolInputCheck.problem(Data(#""x""#.utf8), schema: nullable) == nil)
        #expect(ToolInputCheck.problem(Data(#""z""#.utf8), schema: nullable) != nil)
        // A field written as anyOf with null may be left out, like a type union with null.
        let object = Data(#"""
        {"type":"object","required":["k"],"properties":{"k":{"anyOf":[{"type":"string"},{"type":"null"}]}}}
        """#.utf8)
        #expect(ToolInputCheck.problem(Data("{}".utf8), schema: object) == nil)
    }

    @Test func argumentsNestedTooDeeplyAreRefused() throws {
        var lists: [String: Any] = ["type": "array"]
        for _ in 0 ..< 30 {
            lists = ["type": "array", "items": lists]
        }
        let schema = try JSONSerialization.data(withJSONObject: lists)
        let deep = Data((String(repeating: "[", count: 30) + String(repeating: "]", count: 30)).utf8)
        #expect(ToolInputCheck.problem(deep, schema: schema)?.contains("nest too deeply") == true)
        let shallow = Data("[[[]]]".utf8)
        #expect(ToolInputCheck.problem(shallow, schema: schema) == nil)
    }

    @Test @MainActor func everySchemaTessSendsIsReadable() {
        // A schema the check can't read checks nothing, so every one she sends must read as an object schema.
        for spec in TessRun.toolSpecs() + TessRun.shellSpecs() + [TessRun.tryLookSpec] {
            let schema = (try? JSONSerialization.jsonObject(with: spec.schema)) as? [String: Any]
            #expect(schema?["type"] as? String == "object", "\(spec.name)")
        }
    }
}
