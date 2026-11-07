# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Compat.StrSlugTest do
  use MishkaSlug.CompatCase

  @moduledoc """
  The cases of the Rust `str_slug` crate, run against `MishkaSlug`.

  Source: https://github.com/OussamaElgoumri/str_slug, `src/lib.rs` (`mod tests`), MIT. The
  strings are the crate's; the original column is what `str_slug::slug` returns.

  Not ported: the hash suffix and the options that keep or repeat separators.

  | Difference | Why |
  |---|---|
  | `Æ`, `☣` | The crate writes `ae` and `biohazard`; we keep the letter and drop the symbol. |
  """

  @transliterated "the crate writes ASCII names for letters and symbols; we keep the letter and drop the symbol"

  @cases [
    {"   Hello, world!", [], "hello-world", "hello-world", nil},
    {"Hello, ascii", [], "hello-ascii", "hello-ascii", nil},
    {"Æ, ☣", [], "ae-biohazard", "æ", @transliterated},
    {"Hello, Æ, ☣", [], "hello-ae-biohazard", "hello-æ", @transliterated},
    {"Hello, ❤ ;-)", [], "hello", "hello", nil}
  ]

  compat_cases(@cases)
end
