# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Compat.LocaleSlugTest do
  use MishkaSlug.CompatCase

  @moduledoc """
  The cases and invariants of `locale_slug`, run against `MishkaSlug`.

  Source: https://github.com/mdon/locale_slug, `test/locale_slug_test.exs` and
  `test/invariants_test.exs`, MIT. The strings are the project's; the original column is what
  `LocaleSlug.slugify/2` returns for the same locale (our `:language`), with its default
  `fallback: :native`. A `locale_slug` result of `""` is `:empty` here.

  Not ported: the romanisation tables per standard (BGN/PCGN, KMU 55:2010, ISO 843, ...), the
  `:schema`, `:script`, `:fallback` and `:separator` options and `transliterate/2`.

  | Difference | Why |
  |---|---|
  | Letters outside ASCII | `locale_slug` romanises Latin, Cyrillic and Greek; we keep each script. |
  | Digits | `locale_slug` folds every digit to `0-9`; we keep digits as typed unless `digits: :ascii`. |
  | Final sigma | `locale_slug` writes `ς` for a word-final capital sigma always; we need `language: "el"`. |
  """

  @romanised "locale_slug romanises this script to ASCII; we keep the script's own letters"
  @umlaut "locale_slug expands or folds the letter by locale; we keep it and only lowercase"

  @cases [
    {"Größe Fußball", [language: "de"], "groesse-fussball", "größe-fußball", @umlaut},
    {"Töö õun", [language: "et"], "too-oun", "töö-õun", @umlaut},
    {"Öl", [language: "de"], "oel", "öl", @umlaut},
    {"Öl", [language: "et"], "ol", "öl", @umlaut},
    {"Größe Fußball", [], "grosse-fussball", "größe-fußball", @umlaut},
    {"Łódź", [], "lodz", "łódź", @romanised},
    {"Rødgrød med fløde", [], "rodgrod-med-flode", "rødgrød-med-fløde", @romanised},
    {"Işık", [], "isik", "işık", @romanised},
    {"Işık", [language: "tr"], nil, "ışık",
     "locale_slug has no Turkish table; with `tr` we lowercase `I` to the dotless `ı`"},
    {"Æther", [], "aether", "æther", @romanised},
    {"فصل ٢", [], "فصل-2", "فصل-٢",
     "locale_slug folds every digit to `0-9`; we keep digits as typed"},
    {"فصل ٢", [digits: :ascii], "فصل-2", "فصل-2", nil},
    {"模型 ３", [], "模型-3", "模型-3", nil},
    {"Цветокоррекция", [], "tsvetokorrektsiya", "цветокоррекция", @romanised},
    {"Ежик", [], "yezhik", "ежик", @romanised},
    {"Київ", [language: "uk"], "kyiv", "київ", @romanised},
    {"Ђорђе", [language: "sr"], "djordje", "ђорђе", @romanised},
    {"Καλημέρα", [], "kalimera", "καλημέρα", @romanised},
    {"Αλέξανδρος", [], "alexandros", "αλέξανδρος", @romanised},
    {"ΑΛΕΞΑΝΔΡΟΣ", [language: "el"], "alexandros", "αλεξανδρος", @romanised},
    {"ΑΛΕΞΑΝΔΡΟΣ", [], "alexandros", "αλεξανδροσ",
     "a word-final capital sigma becomes `ς` only with `language: \"el\"`"},
    {"iPhone 15 Проблема", [], "iphone-15-problema", "iphone-15-проблема", @romanised},
    {"日本語 入門", [], "日本語-入門", "日本語-入門", nil},
    {"Цветокоррекция", [], "цветокоррекция", "цветокоррекция", nil},
    {"", [], :empty, :empty, nil},
    {"!!! ???", [], :empty, :empty, nil},
    {"   ", [], :empty, :empty, nil},
    {"a:b/c?d#e[f]g@h!i$j&k(m)n*o+p,q;r=s", [], "a-b-c-d-e-f-g-h-i-j-k-m-n-o-p-q-r-s",
     "a-b-c-d-e-f-g-h-i-j-k-m-n-o-p-q-r-s", nil}
  ]

  compat_cases(@cases)

  @corpus [
    "Größe Fußball",
    "Töö õun",
    "Łódź",
    "Rødgrød med fløde",
    "Işık",
    "İSTANBUL Işık",
    "Цветокоррекция",
    "объект",
    "Щука наша",
    "Київ Європа",
    "Їжак Ґанок",
    "Ђорђе Њива Џем",
    "Καλημέρα κόσμε",
    "ΑΛΕΞΑΝΔΡΟΣ",
    "μπύρα και λάμπα",
    "iPhone 15 Проблема",
    "日本語 入門",
    "مرحبا بالعالم",
    "قیمت\u{200C}گذاری نرم\u{200C}افزار",
    "हिन्दी भाषा",
    "สวัสดีชาวโลก",
    "",
    "   ",
    "!!! ???",
    "---",
    "a",
    "ß",
    "ς",
    "🎉 emoji 🎉",
    "a\u{200D}b",
    String.duplicate("Größe ", 200)
  ]

  @languages [nil, "de", "et", "ru", "uk", "bg", "sr", "el", "tr", "fa"]

  defp each_case(fun) do
    for text <- @corpus, language <- @languages do
      fun.(text, if(language, do: [language: language], else: []))
    end
  end

  defp slug(text, opts) do
    case MishkaSlug.slugify(text, opts) do
      {:ok, slug} -> slug
      {:error, reason} -> reason
    end
  end

  test "a slug holds only letters, marks, digits and single inner hyphens" do
    each_case(fn text, opts ->
      with {:ok, slug} <- MishkaSlug.slugify(text, opts) do
        assert slug =~ ~r/\A[\p{L}\p{M}\p{Nd}]+(-[\p{L}\p{M}\p{Nd}]+)*\z/u,
               "#{inspect(text)} #{inspect(opts)} -> #{inspect(slug)}"
      end
    end)
  end

  test "slugging a slug again changes nothing" do
    each_case(fn text, opts ->
      with {:ok, slug} <- MishkaSlug.slugify(text, opts) do
        assert MishkaSlug.slugify(slug, opts) == {:ok, slug},
               "#{inspect(text)} #{inspect(opts)} -> #{inspect(slug)}"
      end
    end)
  end

  test "decomposed and composed input give the same slug" do
    each_case(fn text, opts ->
      assert slug(String.normalize(text, :nfc), opts) == slug(String.normalize(text, :nfd), opts),
             "#{inspect(text)} #{inspect(opts)}"
    end)
  end

  test "German letters written decomposed still lowercase as the language says" do
    assert MishkaSlug.slugify("O\u{0308}l", language: "de") == {:ok, "öl"}
    assert MishkaSlug.slugify("Gro\u{00DF}e", language: "de") == {:ok, "große"}
  end

  test "max_length bounds the slug in code points and never ends it in a hyphen" do
    for text <- @corpus, language <- @languages, length <- [1, 2, 3, 5, 8, 13, 40] do
      opts = [max_length: length] ++ if(language, do: [language: language], else: [])

      case MishkaSlug.slugify(text, opts) do
        {:ok, slug} ->
          assert length(String.to_charlist(slug)) <= length,
                 "#{inspect(text)} #{inspect(opts)} -> #{inspect(slug)}"

          refute String.ends_with?(slug, "-")
          assert MishkaSlug.slugify(slug, opts) == {:ok, slug}

        {:error, :empty} ->
          :ok
      end
    end
  end

  test "no URL reserved character survives and the slug is NFC" do
    reserved = ~w(: / ? # [ ] @ ! $ & ' \( \) * + , ; =)

    each_case(fn text, opts ->
      slug = slug(text, opts)

      if is_binary(slug) do
        assert slug == String.normalize(slug, :nfc)
        for char <- reserved, do: refute(String.contains?(slug, char), "#{char} in #{slug}")
      end
    end)
  end

  test "a large input is slugged and keeps its letters" do
    big = String.duplicate("Größe Fußball Цветокоррекция ", 500)

    assert {:ok, slug} = MishkaSlug.slugify(big, language: "de")
    assert String.length(slug) > 1000
    assert slug =~ ~r/\A[\p{L}\p{Nd}-]+\z/u
  end
end
