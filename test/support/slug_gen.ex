# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.SlugGen do
  @moduledoc """
  StreamData generators for the property tests of `MishkaSlug.slugify/2`.

  `text/0` mixes ASCII words, every script the library knows, combining marks, Hangul jamo after
  grapheme-prepending signs, emoji, ZWJ sequences, bidi controls, controls, invisibles, no-break
  spaces, code points next to the surrogate range, unassigned code points and arbitrary scalar
  values. `options/0` draws every
  option the library accepts.
  """

  import StreamData
  import ExUnitProperties

  @languages [nil, "fa", "ar", "tr", "el", "he", "ja", "hi", "th", "ru"]
  @locale_codes ~w(en fa ar tr el he ja hi th ru de fr zh ko)

  @ranges [
    latin: [0x41..0x5A, 0x61..0x7A, 0xC0..0x24F],
    arabic: [0x621..0x64A, 0x660..0x669, 0x671..0x6D3, 0x6F0..0x6F9],
    hebrew: [0x5D0..0x5EA],
    cyrillic: [0x410..0x44F, 0x400..0x45F],
    greek: [0x391..0x3A9, 0x3B1..0x3C9],
    devanagari: [0x905..0x939, 0x93E..0x94D, 0x966..0x96F],
    thai: [0xE01..0xE3A, 0xE40..0xE4E, 0xE50..0xE59],
    han: [0x4E00..0x9FFF],
    hiragana: [0x3041..0x3096],
    katakana: [0x30A1..0x30FA, 0x30FC..0x30FC],
    hangul: [0xAC00..0xD7A3],
    bopomofo: [0x3105..0x312F],
    armenian: [0x531..0x556],
    georgian: [0x10D0..0x10FA],
    other: [0xF40..0xF69, 0x1200..0x1248]
  ]

  @jamo [0x1100..0x11FF, 0xA960..0xA97C, 0xD7B0..0xD7FB, 0xAC00..0xD7A3]

  @prepend [
    0x600..0x605,
    0x6DD..0x6DD,
    0x70F..0x70F,
    0x890..0x891,
    0x8E2..0x8E2,
    0xD4E..0xD4E,
    0x110BD..0x110BD,
    0x110CD..0x110CD,
    0x111C2..0x111C3,
    0x113D1..0x113D1,
    0x1193F..0x1193F,
    0x11941..0x11941,
    0x11A3A..0x11A3A,
    0x11A84..0x11A89,
    0x11D46..0x11D46,
    0x11F02..0x11F02
  ]

  @combining [0x300..0x36F, 0x483..0x487, 0x64B..0x65F, 0x591..0x5BD, 0x93C..0x93C, 0xE31..0xE31]

  @special [
    "\u{200B}",
    "\u{200C}",
    "\u{200D}",
    "\u{200E}",
    "\u{200F}",
    "\u{202A}",
    "\u{202B}",
    "\u{202C}",
    "\u{202D}",
    "\u{202E}",
    "\u{2066}",
    "\u{2067}",
    "\u{2068}",
    "\u{2069}",
    "\u{00AD}",
    "\u{FEFF}",
    "\u{2060}",
    "\u{FE0F}",
    "\u{3164}",
    "\u{00A0}",
    "\u{3000}",
    "\u{2028}",
    "\u{2029}",
    "\u{0085}",
    "\t",
    "\n",
    "\r",
    "\u{0000}",
    "\u{001F}",
    "\u{007F}",
    "\u{D7FF}",
    "\u{E000}",
    "\u{F8FF}",
    "\u{FFFE}",
    "\u{FFFF}",
    "\u{10FFFF}",
    "\u{E0001}",
    "\u{0378}",
    "\u{0640}",
    "\u{FB01}",
    "\u{FF21}",
    "\u{2126}",
    "\u{0130}",
    "\u{0049}",
    "\u{03A3}",
    "'",
    "\u{2019}",
    "\u{2014}",
    "\u{2026}"
  ]

  @emoji ["😀", "🚀", "👨‍👩‍👧‍👦", "🏳️‍🌈", "👍🏽", "1️⃣", "🇮🇷", "❤️", "©", "™"]

  @punctuation String.graphemes(".,:;!?'\"()-_/&@#%\\<>[]{}|*+=~^`$")

  @doc "A code point range as a one-character string."
  @spec char([Range.t()]) :: StreamData.t(String.t())
  def char(ranges), do: ranges |> Enum.map(&integer/1) |> one_of() |> map(&<<&1::utf8>>)

  @doc """
  The NFC form of `text`, with Hangul composed even where OTP's normalizer misses it.

  OTP composes one grapheme cluster at a time and only composes jamo at the start of a cluster, so
  a prepended sign (`U+113D1`) or an archaic leading jamo leaves the jamo after it decomposed. A
  Hangul leading jamo or syllable is never the second half of a composition, so cutting the text
  before each one and normalizing the pieces gives the true NFC.
  """
  @spec nfc(String.t()) :: String.t()
  def nfc(text) do
    text
    |> String.split(~r/(?=[\x{1100}-\x{1112}\x{AC00}-\x{D7A3}])/u)
    |> Enum.map_join(&String.normalize(&1, :nfc))
  end

  @doc "A scalar value from the whole Unicode range, surrogates excluded."
  @spec scalar() :: StreamData.t(String.t())
  def scalar do
    0..0x10FFFF
    |> integer()
    |> map(fn cp -> if cp in 0xD800..0xDFFF, do: <<cp + 0x800::utf8>>, else: <<cp::utf8>> end)
  end

  @doc "A short run of letters of one script, or of random scalar values."
  @spec chunk() :: StreamData.t(String.t())
  def chunk do
    script_runs =
      for {_script, ranges} <- @ranges do
        ranges |> char() |> list_of(min_length: 1, max_length: 8) |> map(&Enum.join/1)
      end

    frequency([
      {8, one_of(script_runs)},
      {3, @combining |> char() |> list_of(min_length: 1, max_length: 3) |> map(&Enum.join/1)},
      {3, member_of(@special)},
      {2, member_of(@emoji)},
      {3, member_of(@punctuation)},
      {2, string(?0..?9, min_length: 1, max_length: 5)},
      {3, scalar()},
      {2,
       [@prepend, @jamo]
       |> Enum.map(&char/1)
       |> one_of()
       |> list_of(min_length: 1, max_length: 4)
       |> map(&Enum.join/1)},
      {2, member_of([" ", "  ", " \t "])}
    ])
  end

  @doc "Any valid UTF-8 text built from `chunk/0` pieces, sometimes very long."
  @spec text() :: StreamData.t(String.t())
  def text do
    short = chunk() |> list_of(max_length: 12) |> map(&Enum.join/1)

    long = chunk() |> list_of(min_length: 100, max_length: 200) |> map(&Enum.join(&1, " "))

    frequency([{20, short}, {1, long}, {3, string(:printable, max_length: 30)}])
  end

  @doc "A list of 1 to 6 words, each a run of letters of one plain script (Latin or Cyrillic)."
  @spec plain_words() :: StreamData.t([String.t()])
  def plain_words do
    latin = string(Enum.concat([?a..?z, ?0..?9]), min_length: 1, max_length: 8)
    cyrillic = string(0x430..0x44F, min_length: 1, max_length: 8)
    list_of(one_of([latin, cyrillic]), min_length: 1, max_length: 6)
  end

  @doc """
  A keyword list with any combination of the options `MishkaSlug.slugify/2` accepts.

  With `locales: :none` the generated `:locales` is always `[]`, so no script is dropped; with
  `locales: :some` it is never empty.
  """
  @spec options(keyword()) :: StreamData.t(keyword())
  def options(opts \\ []) do
    fixed_map(%{
      language: member_of(@languages),
      locales: locales(opts[:locales]),
      mixed_scripts: member_of([:split, :reject]),
      zwnj: member_of([:remove, :separator]),
      digits: member_of([:keep, :ascii]),
      latin: member_of([:ascii, :keep]),
      keep: keep(),
      trim_kept: boolean(),
      max_length: one_of([constant(nil), integer(1..40)])
    })
    |> map(&Map.to_list/1)
  end

  @doc "A list of locale codes: empty, non-empty or either."
  @spec locales(:none | :some | nil) :: StreamData.t([String.t()])
  def locales(kind \\ nil)
  def locales(:none), do: constant([])

  def locales(:some),
    do: @locale_codes |> member_of() |> list_of(min_length: 1, max_length: 3) |> map(&Enum.uniq/1)

  def locales(nil), do: frequency([{2, locales(:none)}, {3, locales(:some)}])

  @doc "A subset of the characters `:keep` accepts."
  @spec keep() :: StreamData.t([String.t()])
  def keep do
    frequency([
      {3, constant([])},
      {2, [".", "_", "~"] |> member_of() |> list_of(max_length: 3) |> map(&Enum.uniq/1)}
    ])
  end

  @doc "A plain English title: ASCII words and the punctuation of blog headlines, any case."
  @spec english_title() :: StreamData.t(String.t())
  def english_title do
    word =
      frequency([
        {6, string(Enum.concat(?a..?z, ?A..?Z), min_length: 1, max_length: 9)},
        {2, string(?0..?9, min_length: 1, max_length: 4)},
        {2, string(Enum.concat([?a..?z, ?A..?Z, ?0..?9]), min_length: 1, max_length: 9)}
      ])

    junk =
      [
        " ",
        "  ",
        ", ",
        ": ",
        "; ",
        "! ",
        "? ",
        ". ",
        " - ",
        "_",
        "/",
        " & ",
        "@",
        "#",
        "(",
        ")",
        "\"",
        "'",
        "'s ",
        "n't "
      ]
      |> member_of()

    part = one_of([word, junk])

    ends =
      [" ", "  ", ".", "!", "?", "\"", "(", ")", "-", "--", "...", "_", "/", "#"] |> member_of()

    gen all(
          lead <- list_of(ends, max_length: 2),
          parts <- list_of(part, min_length: 1, max_length: 14),
          trail <- list_of(ends, max_length: 2)
        ) do
      Enum.join(lead ++ parts ++ trail)
    end
  end
end
