# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Compat.RustSlugTest do
  use MishkaSlug.CompatCase

  @moduledoc """
  The cases of the Rust `slug` crate, run against `MishkaSlug`.

  Source: https://github.com/Stebalien/slug-rs, `src/lib.rs` (the `slugify` doc tests),
  Apache-2.0. The strings are the crate's; the original column is what `slug::slugify` returns.
  Its `deunicode` step writes ASCII for every other script; we keep the script.

  | Difference | Why |
  |---|---|
  | `Æúű` | `deunicode` writes `aeuu`; we keep the letters. |
  """

  @cases [
    {"My Test String!!!1!1", [], "my-test-string-1-1", "my-test-string-1-1", nil},
    {"test\nit   now!", [], "test-it-now", "test-it-now", nil},
    {"  --test_-_cool", [], "test-cool", "test-cool", nil},
    {"Æúű--cool?", [], "aeuu-cool", "æúű-cool", "deunicode writes ASCII; we keep the letters"},
    {"You & Me", [], "you-me", "you-me", nil},
    {"user@example.com", [], "user-example-com", "user-example-com", nil}
  ]

  compat_cases(@cases)
end
