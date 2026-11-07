# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Compat.SimpleSlugTest do
  use MishkaSlug.CompatCase

  @moduledoc """
  The behaviours of `simple_slug`, run against `MishkaSlug`.

  Source: https://github.com/vforgione/simple_slug, `lib/simple_slug.ex` and
  `test/simple_slugs_test.exs` (which only runs the doctests), GPL-3.0. The project is GPL, so
  none of its examples is copied: the inputs are our own, and the original column is what
  `SimpleSlug.slugify/2` gives, which splits only on the code points U+0000 to U+002F.

  | Difference | Why |
  |---|---|
  | `? : ; = @ [ ]` | `simple_slug` leaves them in the slug; they are URL delimiters, so we break there. |
  | Non-ASCII spaces and dashes | `simple_slug` keeps `U+00A0` and `—`; they separate words for us. |
  | Invisible characters | `simple_slug` keeps them; we remove them. |
  | Mixed scripts | `simple_slug` does not look at scripts; we split a word that changes script. |
  """

  @delimiter "simple_slug splits only on U+0000 to U+002F, so this URL delimiter stays in its slug"

  @cases [
    {"Grüße aus Köln", [], "grüße-aus-köln", "grüße-aus-köln", nil},
    {"京都タワー観光2019年3月", [], "京都タワー観光2019年3月", "京都タワー観光2019年3月", nil},
    {"Hello, World!", [], "hello-world", "hello-world", nil},
    {"Hello World", [max_length: 5], "hello", "hello", nil},
    {"Hello World", [max_length: 6], "hello", "hello", nil},
    {"tab\there", [], "tab-here", "tab-here", nil},
    {"what? yes: ok", [], "what?-yes:-ok", "what-yes-ok", @delimiter},
    {"a/b?c=d", [], "a-b?c=d", "a-b-c-d", @delimiter},
    {"user@host", [], "user@host", "user-host", @delimiter},
    {"[draft];final", [], "[draft];final", "draft-final", @delimiter},
    {"a\u{00A0}b", [], "a\u{00A0}b", "a-b", "`U+00A0` is not in U+0000 to U+002F, so it is kept"},
    {"Ünï ĉode — dash", [], "ünï-ĉode-—-dash", "ünï-ĉode-dash",
     "`—` is not in U+0000 to U+002F, so it is kept"},
    {"pay\u{200B}pal", [], "pay\u{200B}pal", "paypal",
     "`simple_slug` keeps the zero-width space; we remove invisible characters"},
    {"p\u{0430}ypal", [], "p\u{0430}ypal", "p-\u{0430}-ypal",
     "`simple_slug` keeps a word that mixes Latin and Cyrillic; we split it at the change"}
  ]

  compat_cases(@cases)
end
