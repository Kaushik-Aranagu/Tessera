#!/usr/bin/env python3
"""Tests for the ruled pinned-line change path in premerge_check.py.

Run: python3 -B -I scripts/ops/test_premerge_pin.py
"""
import importlib.util
import os
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location("premerge_check", os.path.join(HERE, "premerge_check.py"))
pc = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pc)

PATH = "docs/design/motion/example-lowpower.md"
OLD = "| Settings, pin a look | paint flood 700 ms | flood is one pass and stays |"
NEW = "| Settings, pin a look | paint flood 700 ms | flood runs in normal power; Reduce Motion crossfades 150 ms |"
STAMP = "11:33 AM PT Oct 18"
DECISIONS = (
    "# Product decisions log\n\n"
    "- 9:00 AM PT Oct 18 (Product, other): something else about other-file.md:67.\n"
    "- " + STAMP + " (Product, QA contradiction): the newer ruling stands. The pinned line at\n"
    "  example-lowpower.md:67 changes to the new text.\n"
    "- 12:00 PM PT Oct 18 (Product, later): unrelated.\n"
)
BODY = "Before: x\nPIN-CHANGE: " + STAMP + " | " + PATH + ":67\n"


def diff(old_lines, new_lines, path=PATH, at=67):
    out = ["diff --git a/%s b/%s" % (path, path), "--- a/%s" % path, "+++ b/%s" % path,
           "@@ -%d,%d +%d,%d @@" % (at, len(old_lines), at, len(new_lines))]
    out += ["-" + line for line in old_lines] + ["+" + line for line in new_lines]
    return "\n".join(out) + "\n"


def run(text, body=None, decisions=None):
    files = pc.parse(text)
    return pc.check(files, pc.kind_of(files), pc.parse_rulings(body), decisions)


def stopped(result):
    return any(why.startswith("pin:") for _, _, why in result[0])


class PinRuling(unittest.TestCase):
    def test_changed_pin_line_without_ruling_stops(self):
        self.assertTrue(stopped(run(diff([OLD], [NEW]))))

    def test_ruling_with_backing_entry_reports_not_stops(self):
        stops, reports = run(diff([OLD], [NEW]), BODY, DECISIONS)
        self.assertEqual(stops, [])
        self.assertTrue(any(STAMP in why and "example-lowpower.md:67" in why for _, _, why in reports))

    def test_missing_entry_stops(self):
        self.assertTrue(stopped(run(diff([OLD], [NEW]), BODY, "# Product decisions log\n")))

    def test_entry_not_naming_this_file_and_line_stops(self):
        body = "PIN-CHANGE: 9:00 AM PT Oct 18 | " + PATH + ":67\n"
        self.assertTrue(stopped(run(diff([OLD], [NEW]), body, DECISIONS)))

    def test_entry_naming_a_different_line_stops(self):
        self.assertTrue(stopped(run(diff([OLD], [NEW], at=68), BODY, DECISIONS)))

    def test_body_citing_entry_without_decisions_file_stops(self):
        self.assertTrue(stopped(run(diff([OLD], [NEW]), BODY, None)))

    def test_install_pin_line_never_ruled(self):
        old = "PIN: install release 13 bbadf141 only."
        self.assertTrue(stopped(run(diff([old], ["PIN: install release 14 only."]), BODY, DECISIONS)))

    def test_second_pin_line_without_its_own_ruling_stops(self):
        other = "| Other, pin a look | flood | flood stays |"
        self.assertTrue(stopped(run(diff([OLD, other], [NEW, other + " x"]), BODY, DECISIONS)))

    def test_new_text_adding_only_sha_stops(self):
        self.assertTrue(stopped(run(diff([OLD], ["| Settings, pin a look | only SHA abcdef1234567 |"]), BODY, DECISIONS)))

    def test_new_text_adding_release_install_stops(self):
        self.assertTrue(stopped(run(diff([OLD], ["| Settings, pin a look | release 14 install |"]), BODY, DECISIONS)))

    def test_partial_stamp_stops(self):
        body = "PIN-CHANGE: 11 | " + PATH + ":67\n"
        decisions = DECISIONS.replace("- " + STAMP, "- 11:33 AM PT Oct 18")
        self.assertTrue(stopped(run(diff([OLD], [NEW]), body, decisions)))

    def test_install_named_file_never_ruled(self):
        path = "docs/ops/pin-release.md"
        body = "PIN-CHANGE: " + STAMP + " | " + path + ":67\n"
        decisions = DECISIONS.replace("example-lowpower.md:67", "pin-release.md:67")
        self.assertTrue(stopped(run(diff([OLD], [NEW], path=path), body, decisions)))

    def test_extra_added_pin_line_stops(self):
        self.assertTrue(stopped(run(diff([OLD], [NEW, "| Another, pin a look | x | y |"]), BODY, DECISIONS)))

    def test_unrelated_edit_untouched(self):
        stops, _ = run(diff(["plain line"], ["other plain line"]))
        self.assertEqual(stops, [])


if __name__ == "__main__":
    unittest.main()
