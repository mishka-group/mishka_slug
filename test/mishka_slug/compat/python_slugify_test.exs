# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Compat.PythonSlugifyTest do
  use MishkaSlug.CompatCase

  @moduledoc """
  The cases of python-slugify, run against `MishkaSlug`.

  Source: https://github.com/un33k/python-slugify, `tests/test_legacy.py` (`TestSlugify` and
  `TestSlugifyUnicode`), MIT. The strings are the project's own; the original column is what
  `slugify` returns, with `allow_unicode=True` for the Unicode rows.

  Not ported: `stopwords`, `replacements`, `regex_pattern`, `separator`, `lowercase=False`,
  `save_order` and `word_boundary` options and the CLI tests. `MishkaSlug` has no such options.

  | Difference | Why |
  |---|---|
  | `'` inside a word | We drop it and keep the word whole; python-slugify breaks the word. |
  | `1,000` | A comma separates, so the digits stay two words; python-slugify joins them. |
  | `&amp;`, `&#381;` | We do not decode HTML entities; `&`, `#` and `;` just separate words. |
  | `max_length` | We keep whole words only; python-slugify cuts inside a word. |
  | ASCII mode | The default of python-slugify transliterates; we keep the script. |
  """

  @apostrophe "an apostrophe between two letters is dropped, so the word stays whole"
  @thousands "a comma is a separator, so the digit groups are separate words"
  @whole_words "only whole words are kept, so the slug stops before a word that does not fit"
  @entities "HTML entities are not decoded, the `&`, `#` and `;` separate words"
  @transliteration "python-slugify transliterates to ASCII by default; we keep the script"

  @cases [
    {"This is a test ---", [], "this-is-a-test", "this-is-a-test", nil},
    {"___This is a test ---", [], "this-is-a-test", "this-is-a-test", nil},
    {"___This is a test___", [], "this-is-a-test", "this-is-a-test", nil},
    {"This -- is a ## test ---", [], "this-is-a-test", "this-is-a-test", nil},
    {"影師嗎", [], "影師嗎", "影師嗎", nil},
    {"影師嗎", [], "ying-shi-ma", "影師嗎", @transliteration},
    {"C'est déjà l'été.", [], "c-est-déjà-l-été", "cest-déjà-lété", @apostrophe},
    {"C'est déjà l'été.", [], "c-est-deja-l-ete", "cest-déjà-lété", @transliteration},
    {"Nín hǎo. Wǒ shì zhōng guó rén", [], "nín-hǎo-wǒ-shì-zhōng-guó-rén",
     "nín-hǎo-wǒ-shì-zhōng-guó-rén", nil},
    {"jaja---lol-méméméoo--a", [], "jaja-lol-méméméoo-a", "jaja-lol-méméméoo-a", nil},
    {"jaja---lol-méméméoo--a", [], "jaja-lol-mememeoo-a", "jaja-lol-méméméoo-a",
     @transliteration},
    {"Компьютер", [], "компьютер", "компьютер", nil},
    {"Компьютер", [], "kompiuter", "компьютер", @transliteration},
    {"jaja---lol-méméméoo--a", [max_length: 9], "jaja-lol", "jaja-lol", nil},
    {"jaja---lol-méméméoo--a", [max_length: 15], "jaja-lol-mémémé", "jaja-lol", @whole_words},
    {"jaja---lol-méméméoo--a", [max_length: 50], "jaja-lol-méméméoo-a", "jaja-lol-méméméoo-a",
     nil},
    {"jaja---lol-méméméoo--a", [max_length: 15], "jaja-lol-a", "jaja-lol",
     "with `word_boundary` python-slugify may skip a long word and take a later one; we never reorder"},
    {"jaja---lol-méméméoo--a", [max_length: 17], "jaja-lol-méméméoo", "jaja-lol-méméméoo", nil},
    {"jaja---lol-méméméoo--a", [max_length: 18], "jaja-lol-méméméoo", "jaja-lol-méméméoo", nil},
    {"jaja---lol-méméméoo--a", [max_length: 19], "jaja-lol-méméméoo-a", "jaja-lol-méméméoo-a",
     nil},
    {"one two three four five", [max_length: 13], "one-two-three", "one-two-three", nil},
    {"one two three four five", [max_length: 12], "one-two", "one-two", nil},
    {"one two three four five", [max_length: 12], "one-two-four", "one-two",
     "python-slugify may skip a word to fill the room; we keep the words in order"},
    {"دو سه چهار پنج", [max_length: 10], "دو-سه-چهار", "دو-سه-چهار", nil},
    {"دو سه چهار پنج", [max_length: 9], "دو-سه", "دو-سه", nil},
    {"دو سه چهار پنج", [max_length: 9], "دو-سه-پنج", "دو-سه",
     "python-slugify may skip a word to fill the room; we keep the words in order"},
    {"foo &amp; bar", [], "foo-bar", "foo-amp-bar", @entities},
    {"foo &amp; bår", [], "foo-amp-bår", "foo-amp-bår", nil},
    {"&#381;", [], "ž", "381", @entities},
    {"&#381;", [], "381", "381", nil},
    {"&#x17D;", [], "x17d", "x17d", nil},
    {"10 amazing secrets", [], "10-amazing-secrets", "10-amazing-secrets", nil},
    {"buildings with 1000 windows", [], "buildings-with-1000-windows",
     "buildings-with-1000-windows", nil},
    {"recipe number 3", [], "recipe-number-3", "recipe-number-3", nil},
    {"404", [], "404", "404", nil},
    {"1,000 reasons you are #1", [], "1000-reasons-you-are-1", "1-000-reasons-you-are-1",
     @thousands},
    {"۱,۰۰۰ reasons you are #۱", [], "۱۰۰۰-reasons-you-are-۱", "۱-۰۰۰-reasons-you-are-۱",
     @thousands},
    {"۱,۰۰۰ reasons you are #۱", [digits: :ascii], nil, "1-000-reasons-you-are-1",
     "python-slugify keeps Persian digits; `digits: :ascii` writes them as 0-9"},
    {"ÜBER Über German Umlaut", [], "ueber-ueber-german-umlaut", "über-über-german-umlaut",
     "python-slugify was given a replacement table for `ü`; we have no table and keep the letter"},
    {"10 | 20 %", [], "10-or-20-percent", "10-20",
     "python-slugify was given a replacement table for `|` and `%`; we have none"},
    {"i love 🦄", [], "i-love", "i-love", nil},
    {"I ♥ 🦄", [], "i", "i", nil},
    {"i love 🦄", [], "🦄", "i-love",
     "python-slugify keeps the emoji only with `regex_pattern`; we never keep emoji"}
  ]

  compat_cases(@cases)
end
