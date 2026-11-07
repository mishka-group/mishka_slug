# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Compat.JoomlaTest do
  use MishkaSlug.CompatCase

  @moduledoc """
  The behaviours Joomla checks in `OutputFilter::stringUrlUnicodeSlug` and `stringURLSafe`, run
  against `MishkaSlug`.

  Source: https://github.com/joomla-framework/filter, `Tests/OutputFilterTest.php`,
  GPL-2.0-or-later. That file is GPL, so none of its strings is copied: the inputs are our own,
  written to exercise the same rule. The original column is what the matching Joomla rule gives.

  | Difference | Why |
  |---|---|
  | `_` | Joomla's Unicode slug keeps underscores, as we do by default; `keep: []` splits there. |
  | `.` | Joomla turns a dot into `-`; so do we, unless `keep: ["."]`. |
  | ASCII-7 mode | `stringURLSafe` transliterates every script; we write only Latin as ASCII. |
  """

  @underscore "Joomla keeps `_` inside a word; `keep: []` makes it a word break"

  @cases [
    {"Release v2.1.0 notes_final?", [], "release-v2-1-0-notes_final",
     "release-v2-1-0-notes_final", nil},
    {"Release v2.1.0 notes_final?", [keep: []], "release-v2-1-0-notes_final",
     "release-v2-1-0-notes-final", @underscore},
    {"Release v2.1.0 notes_final?", [keep: [".", "_"]], nil, "release-v2.1.0-notes_final",
     "Joomla cannot keep a dot; `keep: [\".\"]` keeps `.` inside a word"},
    {"Rock-and-roll  Tour", [], "rock-and-roll-tour", "rock-and-roll-tour", nil},
    {"Café Crème", [], "cafe-creme", "cafe-creme", nil},
    {"Café Crème", [latin: :keep], "cafe-creme", "café-crème",
     "`stringURLSafe` writes ASCII; `latin: :keep` keeps the accented letters"},
    {"Español Русский 한국어", [], nil, "espanol-русский-한국어",
     "Joomla writes ASCII or drops what it cannot map; we keep each word in its script"},
    {"`1234567890-=~!@#$%^&*()_+ qwerty[]\\QWERTY{}|asdf;'ASDF:\"zxcv,./ZXCV<>?", [],
     "1234567890--qwerty-qwerty-asdf-asdf-zxcv-zxcv",
     "1234567890-_-qwerty-qwerty-asdf-asdf-zxcv-zxcv",
     "Joomla leaves a double dash where punctuation touches a dash and drops a lone `_`; we collapse runs and keep a lone `_` like WordPress"},
    {"`1234567890-=~!@#$%^&*()_+ qwerty[]\\QWERTY{}|asdf;'ASDF:\"zxcv,./ZXCV<>?",
     [trim_kept: true], "1234567890--qwerty-qwerty-asdf-asdf-zxcv-zxcv",
     "1234567890-qwerty-qwerty-asdf-asdf-zxcv-zxcv",
     "Joomla leaves a double dash where punctuation touches a dash; we always collapse runs"}
  ]

  compat_cases(@cases)

  test "no printable ASCII punctuation survives in a slug, but `_` inside a word by default" do
    punctuation =
      for cp <- 33..126, not (cp in ?0..?9 or cp in ?a..?z or cp in ?A..?Z), cp != ?', do: cp

    for cp <- punctuation do
      char = <<cp::utf8>>

      assert {:ok, "a-b"} = MishkaSlug.slugify("a#{char}b#{char}", keep: [])
      assert {:error, :empty} = MishkaSlug.slugify(char, trim_kept: true)
    end

    assert {:ok, "a_b_"} = MishkaSlug.slugify("a_b_")
    assert {:ok, "a_b"} = MishkaSlug.slugify("a_b_", trim_kept: true)
  end
end
