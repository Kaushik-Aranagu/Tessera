# QA review: #583 Builder B R1, Review foot line above Tess's band

Head 36927f3. Static, low risk, light depth. Merge-tree clean on master.

- HomeSpatialView.swift: new `footLift` = 56; Review's HomeLinkLine gets `.padding(.bottom, Self.footLift)`. Only the Review page changes; other pages untouched.
- BottomChrome.swift: comment only (key comment reworded to "anything that starts like a Claude key"; no literal, no key-shaped text).
- ReviewFootLineUITests: subclasses SimulatorOnlyTestCase, uses existing `-homePage review` flag, scales 736 by the screen height so it holds on other sizes. `sleep(2)` matches existing UI tests.
- No Catalog, migration, flag, copy or haptic change.

Low: the test asserts maxY of "Notes" only, not the Review link; fine since both sit on one line.

Verdict: PASS at 36927f3.
