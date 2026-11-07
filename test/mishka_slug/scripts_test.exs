# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.ScriptsTest do
  use ExUnit.Case, async: true

  alias MishkaSlug.Scripts

  doctest MishkaSlug.Scripts

  test "every language the CMS offers has scripts, and Latin is always among them" do
    languages =
      ~w(af am ar az be bg bn bs ca ckb cs cy da de el en eo es et eu fa fi fil fr ga gl gu ha he
         hi hr hu hy id is it ja ka kk km kn ko ku ky lo lt lv mk ml mn mr ms mt my nb ne nl no pa
         pl ps pt ro ru sd si sk sl so sq sr sv sw ta te tg th tk tr ug uk ur uz vi yi yo zh zu)

    for language <- languages do
      assert {:ok, scripts} = Scripts.for_locales([language])
      assert :latin in scripts
    end
  end

  test "Japanese includes Han and both kana, Persian is Arabic script" do
    assert {:ok, [:han, :hiragana, :katakana, :latin]} = Scripts.for_locales(["ja"])
    assert {:ok, [:arabic, :latin]} = Scripts.for_locales(["fa"])
    assert {:ok, :any} = Scripts.for_locales([])
  end

  test "a digit of a script follows the allow-list like a letter" do
    assert {:error, :no_allowed_script} = MishkaSlug.slugify("سال ۱۴۰۳", locales: ["en"])
    assert {:error, :no_allowed_script} = MishkaSlug.slugify("٢٠٢٥ १२३", locales: ["en"])
    assert {:ok, "2025-iphone"} = MishkaSlug.slugify("2025 iphone ۱۵", locales: ["en"])
    assert {:ok, "abc-१२३"} = MishkaSlug.slugify("abc ١٢ १२३", locales: ["hi"])
    assert {:ok, "سال۱۴۰۳"} = MishkaSlug.slugify("سال۱۴۰۳", locales: ["fa"])
    assert {:ok, "a"} = MishkaSlug.slugify("a ༢༣", locales: ["en"])
    assert {:error, :no_allowed_script} = MishkaSlug.slugify("\u{F20}\u{300}", locales: ["en"])
    assert {:error, :no_allowed_script} = MishkaSlug.slugify("\u{6F1}\u{300}", locales: ["en"])
  end

  test "digits: :ascii writes a digit as 0-9 before the allow-list, so it is kept" do
    assert {:ok, "1403"} = MishkaSlug.slugify("سال ۱۴۰۳", locales: ["en"], digits: :ascii)

    assert {:ok, "1403-123-23"} =
             MishkaSlug.slugify("۱۴۰۳ १२३ ༢༣", locales: ["en"], digits: :ascii)
  end

  test "a digit of an allowed script never makes a word mixed" do
    assert {:ok, "iphone۱۵"} = MishkaSlug.slugify("iphone۱۵", mixed_scripts: :reject)
    assert {:ok, "iphone۱۵"} = MishkaSlug.slugify("iphone۱۵", locales: ["fa"])
    assert {:ok, "iphone"} = MishkaSlug.slugify("iphone۱۵", locales: ["en"])
  end

  test "a mark of another script never rides on a letter, whatever latin is set to" do
    opts = [
      keep: [],
      max_length: 6,
      language: "he",
      digits: :ascii,
      mixed_scripts: :split,
      zwnj: :separator,
      locales: ["ru", "tr"]
    ]

    for latin <- [:ascii, :keep] do
      assert MishkaSlug.slugify("\u{A7D2}\u{112E3}", [latin: latin] ++ opts) == {:ok, "\u{A7D3}"}
      assert MishkaSlug.slugify("a\u{112E3}b", [latin: latin] ++ opts) == {:ok, "ab"}
      assert MishkaSlug.slugify("a\u{0901}", [latin: latin] ++ opts) == {:ok, "a"}
    end

    assert Scripts.split("a\u{0901}", :any, :split) == {:ok, ["a"]}
    assert Scripts.split("a\u{0301}", [:latin], :split) == {:ok, ["a\u{0301}"]}

    assert Scripts.split("\u{0915}\u{093F}", [:devanagari], :reject) ==
             {:ok, ["\u{0915}\u{093F}"]}
  end
end
