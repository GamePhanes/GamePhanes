"""Regression tests for model response termination handling."""

from __future__ import annotations

import unittest

from integrations.harbor.response_policy import classify_response


class ResponsePolicyTests(unittest.TestCase):
    def test_tool_calls_take_precedence(self) -> None:
        self.assertEqual(classify_response("tool_calls", True), "tools")

    def test_length_without_tools_must_continue(self) -> None:
        self.assertEqual(classify_response("length", False), "continue")

    def test_normal_stop_completes(self) -> None:
        self.assertEqual(classify_response("stop", False), "complete")

    def test_unknown_terminal_state_is_rejected(self) -> None:
        with self.assertRaises(RuntimeError):
            classify_response("content_filter", False)


if __name__ == "__main__":
    unittest.main()
