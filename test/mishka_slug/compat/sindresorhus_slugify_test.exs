# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Compat.SindresorhusSlugifyTest do
  use MishkaSlug.CompatCase

  @moduledoc """
  The cases of `@sindresorhus/slugify`, run against `MishkaSlug`.

  Source: https://github.com/sindresorhus/slugify, `test.js`, MIT. The strings are the project's;
  the original column is what `slugify` returns. Cases that pass `transliterate: false` compare
  against the original run that way, because that is the mode that keeps the script as we do.

  Not ported: `separator`, `customReplacements`, `lowercase`, `preserveLeadingUnderscore`,
  `preserveTrailingDash` and `slugifyWithCounter`. `MishkaSlug` has none of these options.

  | Difference | Why |
  |---|---|
  | camelCase | The original splits `fooBar` into `foo-bar`; we only lowercase. |
  | `&`, `♥`, emoji | The original writes `and`, `love`, `unicorn`; we drop them. |
  | Letters outside ASCII | The original transliterates by default; we keep the letter. |
  | `'s` after a digit or before a letter | We drop an apostrophe only between two letters. |
  | `#` and other URL delimiters | Never kept, even when the original is told to preserve them. |
  | `language: "tr"` | The original transliterates first; we lowercase `I` to `ı`. |
  """

  @camel "we do not split camelCase, the word is only lowercased"
  @words "the original writes a word for the symbol or emoji; we drop it"
  @ascii "the original transliterates to ASCII by default; we keep the letter"
  @delimiter "`#` and `/` are URL delimiters; a slug never keeps them"

  @cases [
    {"Foo Bar", [], "foo-bar", "foo-bar", nil},
    {"foo bar baz", [], "foo-bar-baz", "foo-bar-baz", nil},
    {"foo bar ", [], "foo-bar", "foo-bar", nil},
    {"       foo bar", [], "foo-bar", "foo-bar", nil},
    {"[foo] [bar]", [], "foo-bar", "foo-bar", nil},
    {"UNICORNS AND RAINBOWS", [], "unicorns-and-rainbows", "unicorns-and-rainbows", nil},
    {"Foo Bar2", [], "foo-bar2", "foo-bar2", nil},
    {"Foo ÿ", [], "foo-y", "foo-ÿ", @ascii},
    {"FooBar", [], "foo-bar", "foobar", @camel},
    {"fooBar", [], "foo-bar", "foobar", @camel},
    {"fooBar 123 $#%", [], "foo-bar-123", "foobar-123", @camel},
    {"foo360BAR", [], "foo360-bar", "foo360bar", @camel},
    {"FOO360", [], "foo-360", "foo360", @camel},
    {"FOOBar", [], "foo-bar", "foobar", @camel},
    {"APISection", [], "api-section", "apisection", @camel},
    {"HTML5Parser", [], "html-5-parser", "html5parser", @camel},
    {"Foo & Bar", [], "foo-and-bar", "foo-bar", @words},
    {"foo&bar", [], "foo-and-bar", "foo-bar", @words},
    {"Hællæ, hva skjera?", [], "haellae-hva-skjera", "hællæ-hva-skjera", @ascii},
    {"I ♥ Dogs", [], "i-love-dogs", "i-dogs", @words},
    {"Déjà Vu!", [], "deja-vu", "déjà-vu", @ascii},
    {"foo🦄", [], "foo-unicorn", "foo", @words},
    {"🦄🦄🦄", [], "unicorn-unicorn-unicorn", :empty, @words},
    {"ä ö ü Ä Ö Ü ß", [], "ae-oe-ue-ae-oe-ue-ss", "ä-ö-ü-ä-ö-ü-ß", @ascii},
    {"ố Ừ Đ", [], "o-u-d", "ố-ừ-đ", @ascii},
    {"ث س و", [], "th-s-w", "ث-س-و", @ascii},
    {"چ ی پ", [], "ch-y-p", "چ-ی-پ", @ascii},
    {"ٹ ڈ ھ", [], "t-d-h", "ٹ-ڈ-ھ", @ascii},
    {"ګ ړ څ", [], "g-r-c", "ګ-ړ-څ", @ascii},
    {"Ж п ю", [], "zh-p-yu", "ж-п-ю", @ascii},
    {"ș Ț", [], "s-t", "ș-ț", @ascii},
    {"İ ı Ş ş Ç ç Ğ ğ", [], "i-i-s-s-c-c-g-g", "i-ı-ş-ş-ç-ç-ğ-ğ", @ascii},
    {"Ե ր ե ւ ա ն", [], "ye-r-ye-v-a-n", "ե-ր-ե-ւ-ա-ն", @ascii},
    {"Conway's Law", [], "conways-law", "conways-law", nil},
    {"Don't Repeat Yourself", [], "dont-repeat-yourself", "dont-repeat-yourself", nil},
    {"my parents' rules", [], "my-parents-rules", "my-parents-rules", nil},
    {"it-s-hould-not-modify-t-his", [], "it-s-hould-not-modify-t-his",
     "it-s-hould-not-modify-t-his", nil},
    {"Sindre’s app", [], "sindres-app", "sindres-app", nil},
    {"can’t stop", [], "cant-stop", "cant-stop", nil},
    {"Don't!", [], "dont", "dont", nil},
    {"Conway's, revisited", [], "conways-revisited", "conways-revisited", nil},
    {"can't-stop", [], "cant-stop", "cant-stop", nil},
    {"it's...", [], "its", "its", nil},
    {"(it's)", [], "its", "its", nil},
    {"He said “It's”", [], "he-said-its", "he-said-its", nil},
    {"user's_id", [], "users-id", "users-id", nil},
    {"It's, Bob's, and Sue's.", [], "its-bobs-and-sues", "its-bobs-and-sues", nil},
    {"'tis the season", [], "tis-the-season", "tis-the-season", nil},
    {"rock 'n' roll", [], "rock-n-roll", "rock-n-roll", nil},
    {"1990's, 2000's", [], "1990s-2000s", "1990-s-2000-s",
     "we drop an apostrophe only between two letters, not after a digit"},
    {"foo'sbar", [], "foo-sbar", "foosbar",
     "the original keeps a letter after `'s` apart; we drop the apostrophe between letters"},
    {"it's2", [], "it-s2", "its2",
     "the original keeps a digit after `'s` apart; we drop the apostrophe between letters"},
    {"Déjà’s vu", [], "déjàs-vu", "déjàs-vu", nil},
    {"Sindre's日記", [], "sindres", "sindres-日記",
     "the original drops what it cannot transliterate; we keep Han as its own word"},
    {"foo bar", [], "foo-bar", "foo-bar", nil},
    {"foo#bar", [], "foo-bar", "foo-bar", nil},
    {"foo.bar", [], "foo-bar", "foo-bar", nil},
    {"foo#bar", [keep: ["."]], "foo#bar", "foo-bar", @delimiter},
    {"foo.bar#baz-quux", [keep: [".", "_"]], "foo.bar#baz-quux", "foo.bar-baz-quux", @delimiter},
    {"foo/bar baz", [], "foo/bar-baz", "foo-bar-baz", @delimiter},
    {"Räksmörgås", [language: "sv"], "raksmorgas", "räksmörgås", @ascii},
    {"Fön", [language: "de"], "foen", "fön", @ascii},
    {"ISTANBUL", [language: "tr"], "istanbul", "ıstanbul",
     "the original transliterates `ı` to `i`; we keep the Turkish dotless `ı`"},
    {"ISTANBUL", [language: "tr"], "ıstanbul", "ıstanbul", nil},
    {"İstanbul", [language: "tr"], "istanbul", "istanbul", nil},
    {"BAKI", [language: "az"], "baki", "bakı", "the original transliterates `ı`; we keep it"},
    {"TEST", [language: "tr"], "test", "test", nil},
    {"Déjà Vu", [], "déjà-vu", "déjà-vu", nil},
    {"Räksmörgås", [], "räksmörgås", "räksmörgås", nil},
    {"你好世界", [], "你好世界", "你好世界", nil},
    {"مرحبا", [], "مرحبا", "مرحبا", nil},
    {"हिन्दी", [], "हिन्दी", "हिन्दी", nil},
    {"नमस्ते दुनिया", [], "नमस्ते-दुनिया", "नमस्ते-दुनिया", nil},
    {"Café au lait", [], "café-au-lait", "café-au-lait", nil},
    {"Café's menu", [], "cafés-menu", "cafés-menu", nil},
    {"Hello Déjà Vu", [], "hello-déjà-vu", "hello-déjà-vu", nil},
    {"foo & bar", [], "foo-bar", "foo-bar", nil},
    {"☀️", [], :empty, :empty, nil},
    {"Hello ❤️ world", [], "hello-world", "hello-world", nil},
    {"✈️ Flights", [], "flights", "flights", nil},
    {"Café ☕️", [], "café", "café", nil}
  ]

  compat_cases(@cases)
end
