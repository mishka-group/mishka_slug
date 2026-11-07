# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Compat.UnicodeSecurityTest do
  use MishkaSlug.CompatCase

  @moduledoc """
  The mixed-script, confusable and invisible-character cases of the Unicode Security libraries,
  run against `MishkaSlug`.

  Sources: https://github.com/ivan-podgurskiy/unicode_security (`test/unicode_security/*.exs`,
  MIT) and https://github.com/unicode-rs/unicode-security (`src/tests.rs`, MIT or Apache-2.0).
  The strings are theirs. Those libraries answer with a restriction level or a UTS #39 skeleton,
  not a slug, so the original column is the skeleton where one is meaningful and `nil` otherwise.

  Not ported: identifier status, `mixed_number?` counts, domain and IDNA checks, bidi display
  order and the golden-file runs. `MishkaSlug` has no such API.

  | Difference | Why |
  |---|---|
  | Confusables | A skeleton folds `р` to `p`; we keep the letter and cut the word where the script changes. |
  | Bidi controls | A skeleton reorders the text by the control; we remove it and do not reorder. |
  | Restriction levels | A level says "mixed"; we split the word, or refuse it with `mixed_scripts: :reject`. |
  """

  @split "a restriction level only labels the word; we cut it where the script changes"
  @fold "a skeleton folds the lookalike letter to Latin; we keep it and cut the word at the change"

  @cases [
    {"paypal", [], "paypal", "paypal", nil},
    {"раypal", [], "paypal", "ра-ypal", @fold},
    {"раypal", [mixed_scripts: :reject], nil, :mixed_scripts, @split},
    {"раypal", [locales: ["en"]], nil, "ypal", @split},
    {"gοοgle", [], "google", "g-οο-gle", @fold},
    {"p\u{0430}ypal.com", [], nil, "p-\u{0430}-ypal-com", @split},
    {"pay\u{200D}pal", [], "paypal", "paypal", nil},
    {"pay\u{200C}\u{FE0F}\u{00AD}pal", [], "paypal", "paypal", nil},
    {"\u{034F}\u{061C}\u{E0100}", [], :empty, :empty, nil},
    {"a\u{0}\u{10FFFF}b", [], "ab", "ab", nil},
    {"\u{202E}abc(\u{202C}", [], ")cba", "abc",
     "a skeleton applies the override and mirrors the bracket; we only remove the control"},
    {"a\u{2067}\u{05D0}\u{05D1}\u{2069}b", [], "a\u{05D1}\u{05D0}b", "a-\u{05D0}\u{05D1}-b",
     "a skeleton reorders the Hebrew by the isolate; we remove it and cut at the script change"},
    {"ｓｓｓ", [], "sss", "sss", nil},
    {"\u{FDF3}", [], nil, "\u{0627}\u{0643}\u{0628}\u{0631}",
     "a skeleton spells the ligature out in display order; we expand it in logical order"},
    {"m", [], "rn", "m", "a skeleton folds `m` to `rn`; we do not fold lookalike Latin letters"},
    {"Ωmega", [], nil, "ω-mega", @split},
    {"Teχ", [], nil, "te-χ", @split},
    {"漢a", [], nil, "漢-a", @split},
    {"aねガ", [], nil, "a-ねガ", @split},
    {"a漢한", [], nil, "a-漢한", @split},
    {"aअ", [], nil, "a-अ", @split},
    {"aअا", [], nil, "a-अ-ا", @split},
    {"漢ㄅa", [], nil, "漢ㄅ-a", @split},
    {"漢한", [], nil, "漢한", "Han with Hangul is one family, so Korean is never cut"},
    {"日出은", [], nil, "日出은", "Han with Hangul is one family, so Korean is never cut"},
    {"冬の雪", [], nil, "冬の雪", "Han with Hiragana is one family, so Japanese is never cut"},
    {"幻ㄒㄧㄤ", [], nil, "幻ㄒㄧㄤ", "Han with Bopomofo is one family, so Chinese is never cut"},
    {"aー", [], nil, "aー", "the prolonged sound mark belongs to no single script, so it stays"},
    {"1١", [], nil, "1١",
     "digits of different systems are not different scripts; they stay as typed"},
    {"1١", [digits: :ascii], nil, "11", "`digits: :ascii` writes every digit system as 0-9"},
    {"夏の幻ㄒㄧㄤ", [], nil, "夏の幻-ㄒㄧㄤ",
     "Hiragana and Bopomofo share no family, so the word is cut where Bopomofo starts",
     :known_bug},
    {"夏の幻ㄒㄧㄤ", [mixed_scripts: :reject], nil, :mixed_scripts,
     "Hiragana and Bopomofo share no family, so the word is refused", :known_bug},
    {"한漢の", [], nil, "한漢-の",
     "Hangul and Hiragana share no family, so the word is cut where Hiragana starts", :known_bug}
  ]

  compat_cases(@cases)

  test "composed and decomposed forms of one word give one slug" do
    assert MishkaSlug.slugify("À la carte") == MishkaSlug.slugify("A\u{0300} la carte")
    assert MishkaSlug.slugify("Ç") == MishkaSlug.slugify("C\u{0327}")
  end
end
