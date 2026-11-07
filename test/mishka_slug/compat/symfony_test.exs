# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Compat.SymfonyTest do
  use MishkaSlug.CompatCase

  @moduledoc """
  The `AsciiSlugger` cases of Symfony String, run against `MishkaSlug`.

  Source: https://github.com/symfony/symfony,
  `src/Symfony/Component/String/Tests/Slugger/AsciiSluggerTest.php`, MIT. The strings are
  Symfony's; the original column is what `AsciiSlugger::slug` returns for the locale in the test
  (no locale, unless the case says one in its reason).

  | Difference | Why |
  |---|---|
  | Accents and `ä`, `ғ` | The slugger writes ASCII, by locale (`ä` is `a`, or `ae` for `de`); we keep the letter. |
  | `@` with `en` | The `en` locale writes `@` as `at`; we treat it as a separator. |
  | Emoji | With `withEmoji` Symfony writes their names; we drop every emoji. |
  """

  @ascii "the slugger writes ASCII; we keep the accented letter"
  @emoji "with `withEmoji` and a locale Symfony writes the emoji names; we drop emoji"

  @cases [
    {"", [], :empty, :empty, nil},
    {" foo ", [], "foo", "foo", nil},
    {"foo bar", [], "foo-bar", "foo-bar", nil},
    {"foo@bar", [], "foo-bar", "foo-bar", nil},
    {"foo@bar", [language: "en"], "foo-at-bar", "foo-bar",
     "the `en` locale writes `@` as `at`; we treat it as a separator"},
    {"é$!à", [], "e-a", "é-à", @ascii},
    {"ä", [], "a", "ä", @ascii},
    {"ä", [language: "de"], "ae", "ä", @ascii},
    {"ä", [language: "fr"], "a", "ä", @ascii},
    {"ғ", [], "g", "ғ", @ascii},
    {"ғ", [language: "uz"], "gh", "ғ", @ascii},
    {"un 😺, 🐈‍⬛, et un 🦁 vont au 🏞️", [language: "fr"],
     "un-chat-qui-sourit-chat-noir-et-un-tete-de-lion-vont-au-parc-national", "un-et-un-vont-au",
     @emoji},
    {"un 😺, 🐈‍⬛, et un 🦁 vont au 🏞️", [], "un-et-un-vont-au", "un-et-un-vont-au", nil},
    {"a 😺, 🐈‍⬛, and a 🦁 go to 🏞️... 😍 🎉 💛", [], "a-and-a-go-to", "a-and-a-go-to", nil},
    {"a 😺, 🐈‍⬛, and a 🦁 go to 🏞️... 😍 🎉 💛", [language: "en"],
     "a-grinning-cat-black-cat-and-a-lion-go-to-national-park-smiling-face-with-heart-eyes-party-popper-yellow-heart",
     "a-and-a-go-to", @emoji}
  ]

  compat_cases(@cases)
end
