# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Compat.SlugifyRsTest do
  use MishkaSlug.CompatCase

  @moduledoc """
  The cases of the Rust `slugify-rs` crate, run against `MishkaSlug`.

  Source: https://github.com/spa5k/slugify-rs, `src/lib.rs` (`mod tests`), MIT. The strings are
  the crate's, which follows python-slugify; the original column is what `slugify!` returns.

  Not ported: stop words, `randomness`, custom `separator` and the exact-length cut. A cut inside
  a word (`hello wo`) is not something `max_length` does.

  | Difference | Why |
  |---|---|
  | Non-ASCII letters | The crate transliterates to ASCII; we keep the script. |
  """

  @ascii "the crate transliterates to ASCII; we keep the script's own letters"

  @cases [
    {"hello world", [], "hello-world", "hello-world", nil},
    {"hello world-", [], "hello-world", "hello-world", nil},
    {"hello world ", [], "hello-world", "hello-world", nil},
    {"alice@bob.com", [], "alice-bob-com", "alice-bob-com", nil},
    {"10 amazing secrets", [], "10-amazing-secrets", "10-amazing-secrets", nil},
    {"the 101 dalmatians", [], "the-101-dalmatians", "the-101-dalmatians", nil},
    {"lucky number 7", [], "lucky-number-7", "lucky-number-7", nil},
    {"101", [], "101", "101", nil},
    {"1000 reasons you are #1", [], "1000-reasons-you-are-1", "1000-reasons-you-are-1", nil},
    {"影師嗎", [], "ying-shi-ma", "影師嗎", @ascii},
    {"Æúű--cool?", [], "aeuu-cool", "æúű-cool", @ascii},
    {"Nín hǎo. Wǒ shì zhōng guó rén", [], "nin-hao-wo-shi-zhong-guo-ren",
     "nín-hǎo-wǒ-shì-zhōng-guó-rén", @ascii},
    {"jaja---lol-méméméoo--a", [], "jaja-lol-mememeoo-a", "jaja-lol-méméméoo-a", @ascii},
    {"Компьютер", [], "komp-iuter", "компьютер", @ascii},
    {"hello world", [max_length: 5], "hello", "hello", nil},
    {"hello world", [max_length: 6], "hello", "hello", nil},
    {"the hello world", [max_length: 11], "the-hello", "the-hello", nil}
  ]

  compat_cases(@cases)
end
