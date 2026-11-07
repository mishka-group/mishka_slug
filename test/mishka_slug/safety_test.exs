# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.SafetyTest do
  use ExUnit.Case, async: true

  @moduledoc """
  The rules that are always on: invisible characters disappear without leaving a break, a word
  never mixes scripts, and no slug can hold a URL delimiter, a path segment like `..`, or anything
  that is not NFC.
  """

  @attacks [
    {"bidi override and isolates",
     "abc\u{202E}def\u{202C} ghi\u{2066}x\u{2069} \u{200E}فارسی\u{200F}", "abcdef-ghix-فارسی"},
    {"zero-width characters inside a word", "pay\u{200B}pal\u{2060}x\u{00AD}y\u{FEFF}z",
     "paypalxyz"},
    {"Hangul filler", "a\u{3164}b", "ab"},
    {"right-to-left override in a file name", "evil\u{202E}gnp.exe", "evilgnp-exe"},
    {"homoglyph with a Cyrillic letter", "p\u{0430}ypal", "p-а-ypal"},
    {"URL delimiters", "a/b?c#d%e\\f:g", "a-b-c-d-e-f-g"},
    {"path traversal", "../../etc/passwd", "etc-passwd"},
    {"no-break and ideographic spaces", "a\u{00A0}b\u{3000}c", "a-b-c"},
    {"line breaks and tabs", "hello\nworld\tagain", "hello-world-again"},
    {"emoji inside text", "😀 Launch 🚀 day", "launch-day"},
    {"variation selector after a letter", "a\u{FE0F}b", "ab"},
    {"private-use character", "a\u{E000}b", "ab"}
  ]

  for {name, title, slug} <- @attacks do
    test "#{name} gives a clean slug" do
      assert {:ok, unquote(slug)} = MishkaSlug.slugify(unquote(title))
    end
  end

  test "a title of only emoji, punctuation or spaces has no slug" do
    assert {:error, :empty} = MishkaSlug.slugify("😀🚀")
    assert {:error, :empty} = MishkaSlug.slugify("  !!!  ")
    assert {:error, :empty} = MishkaSlug.slugify("")
  end

  test "text that is not UTF-8 is refused" do
    assert {:error, :invalid_utf8} = MishkaSlug.slugify(<<255, 254>>)
  end

  test "slugify! raises on a title without a slug" do
    assert_raise ArgumentError, ~r/:empty/, fn -> MishkaSlug.slugify!("!!!") end
  end

  test "Hangul after a grapheme-prepending sign or an archaic jamo is composed and keeps U+11A7, so it is stable" do
    for {title, slug} <- [
          {"\u{113D1}\u{C0C8}", "\u{113D1}-\u{C0C8}"},
          {"\u{0D4E}\u{1109}\u{1162}\u{11AB}", "\u{0D4E}-\u{C0CC}"},
          {"\u{1113}\u{C0C8}", "\u{1113}\u{C0C8}"},
          {"\u{0D4E}\u{B0EC}\u{11A7}", "\u{0D4E}-\u{B0EC}\u{11A7}"},
          {"\u{1102}\u{1164}\u{11A7}", "\u{B0EC}\u{11A7}"}
        ] do
      assert MishkaSlug.slugify(title) == {:ok, slug}
      assert MishkaSlug.slugify(slug) == {:ok, slug}
    end
  end

  describe "every slug" do
    @corpus Enum.map(@attacks, &elem(&1, 1)) ++
              [
                "قیمت\u{200C}گذاری ۱۴۰۳",
                "हिन्दी भाषा",
                "สวัสดีชาวโลก",
                "東京キャブ乗り場",
                "e\u{200B}\u{0301}tude",
                "a\u{0301}\u{200B}\u{0308}",
                "ا\u{064E}\u{0654}مر",
                "v1.2 .. ...",
                "ΟΔΟΣ",
                "İIıi",
                "\u{113D1}\u{C0C8}",
                "\u{1113}\u{1109}\u{1162}"
              ]

    test "is idempotent and safe for a URL path segment" do
      for title <- @corpus,
          opts <- [
            [],
            [keep: ["."]],
            [keep: []],
            [latin: :keep],
            [digits: :ascii],
            [zwnj: :separator]
          ] do
        {:ok, slug} = MishkaSlug.slugify(title, opts)

        assert {:ok, ^slug} = MishkaSlug.slugify(slug, opts)
        assert_url_safe(slug)
      end
    end

    test "is safe for any valid UTF-8 input" do
      :rand.seed(:exsss, {1, 2, 3})

      for _ <- 1..2_000 do
        title = random_text(:rand.uniform(12))

        case MishkaSlug.slugify(title) do
          {:ok, slug} ->
            assert_url_safe(slug)
            assert {:ok, ^slug} = MishkaSlug.slugify(slug)

          {:error, reason} ->
            assert reason == :empty
        end
      end
    end
  end

  defp assert_url_safe(slug) do
    assert slug == MishkaSlug.SlugGen.nfc(slug)
    refute slug =~ ~r"[/?#%\\:\s]"u
    refute slug =~ ~r/[\p{Cc}\p{Cf}\p{Co}\p{Cn}\p{Bidi_Control}\p{Default_Ignorable_Code_Point}]/u
    refute slug =~ ~r/^-|-$|--/
    refute slug in [".", ".."]
  end

  defp random_text(length) do
    for _ <- 1..length, into: "" do
      <<random_codepoint()::utf8>>
    end
  end

  defp random_codepoint do
    case Enum.random([:ascii, :bmp, :any]) do
      :ascii -> Enum.random(0..0x7F)
      :bmp -> Enum.random(0x80..0xFFFF)
      :any -> Enum.random(0..0x10FFFF)
    end
    |> then(fn cp -> if cp in 0xD800..0xDFFF, do: ?a, else: cp end)
  end
end
