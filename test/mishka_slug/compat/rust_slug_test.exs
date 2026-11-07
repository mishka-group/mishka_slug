# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Compat.RustSlugTest do
  use MishkaSlug.CompatCase

  @moduledoc """
  The cases of the Rust `slug` crate, run against `MishkaSlug`.

  Source: https://github.com/Stebalien/slug-rs, `src/lib.rs` (the `slugify` doc tests),
  Apache-2.0. The strings are the crate's; the original column is what `slug::slugify` returns.
  Its `deunicode` step writes ASCII for every script; we do that for Latin only and keep the
  others. Every case here agrees.
  """

  @cases [
    {"My Test String!!!1!1", [], "my-test-string-1-1", "my-test-string-1-1", nil},
    {"test\nit   now!", [], "test-it-now", "test-it-now", nil},
    {"  --test_-_cool", [trim_kept: true], "test-cool", "test-cool", nil},
    {"  --test_-_cool", [], "test-cool", "test_-_cool",
     "the crate makes `_` a separator; we keep it like WordPress"},
    {"Æúű--cool?", [], "aeuu-cool", "aeuu-cool", nil},
    {"Æúű--cool?", [latin: :keep], "aeuu-cool", "æúű-cool",
     "`latin: :keep` leaves the letters as typed; deunicode writes ASCII"},
    {"You & Me", [], "you-me", "you-me", nil},
    {"user@example.com", [], "user-example-com", "user-example-com", nil}
  ]

  compat_cases(@cases)
end
