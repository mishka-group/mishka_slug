# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Compat.SlugIntlTest do
  use MishkaSlug.CompatCase

  @moduledoc """
  The cases of the Rust `slug_intl` crate, run against `MishkaSlug`.

  Source: https://github.com/danieldickison/slug_intl, `src/lib.rs` (the `slugify` doc tests),
  MIT. The strings are the crate's; the original column is what `slug_intl::slugify` returns.
  It is the closest to us: it keeps Unicode letters, and it also keeps symbols and emoji. Its
  rows with accented Latin letters run with `latin: :keep`, the mode that keeps them too.

  Not ported: the percent-encoding example, which `MishkaSlug` leaves to the caller as well.

  | Difference | Why |
  |---|---|
  | Emoji and symbols | The crate keeps them (`🐠`, `≈`, `£`); we treat them as separators or drop them. |
  """

  @symbols "the crate keeps symbols and emoji; a slug of ours holds only letters, marks and digits"

  @cases [
    {"Hello", [], "hello", "hello", nil},
    {"Hello World", [], "hello-world", "hello-world", nil},
    {"Hello World!", [], "hello-world", "hello-world", nil},
    {"/?&#Hello\n\r\n\r   --World!!!", [], "hello-world", "hello-world", nil},
    {"おはよう、世界！！", [], "おはよう-世界", "おはよう-世界", nil},
    {"おはよう🐠", [], "おはよう🐠", "おはよう", @symbols},
    {"¡¡1≈3∞5=¶£9!!", [], "1≈3∞5=-£9", "1-3-5-9", @symbols},
    {"Hello 🐠", [], "hello-🐠", "hello", @symbols},
    {"ame\u{0301}lie", [latin: :keep], "amélie", "amélie", nil},
    {"ame\u{0301}lie", [], "amélie", "amelie",
     "`latin: :ascii` drops the accent, as WordPress does; the crate keeps it"}
  ]

  compat_cases(@cases)
end
