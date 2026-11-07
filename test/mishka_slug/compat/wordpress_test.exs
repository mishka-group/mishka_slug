# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Compat.WordPressTest do
  use MishkaSlug.CompatCase

  @moduledoc """
  The behaviours WordPress checks in `sanitize_title_with_dashes`, run against `MishkaSlug`.

  Source: https://github.com/WordPress/wordpress-develop,
  `tests/phpunit/tests/formatting/sanitizeTitleWithDashes.php` and `sanitizeTitle.php`,
  GPL-2.0-or-later. These files are GPL, so no string or table is copied here: the inputs are
  our own, written to exercise the same rule. The original column is what the matching WordPress
  rule gives (`save` context, decoded from the percent-encoding it returns). Its locale rules
  for accents (`de`, `da`, `ca`, `sr`, `bs`) are compared with the same code as our `:language`.

  | Difference | Why |
  |---|---|
  | HTML tags | WordPress strips them; we do not parse HTML, the tag names become words. |
  | Entities | WordPress drops `&nbsp;` and `&amp;`; we do not decode them, the names become words. |
  | `&`, `%` inside a word | WordPress deletes them and joins the parts; we break the word. |
  | Latin diacritics with `latin: :keep` | WordPress always replaces them with ASCII, as our default does. |
  | `×`, `™` | WordPress maps them to `x` and drops `™`; `×` separates and `™` folds to `tm`. |
  | `_` at a word's ends | WordPress keeps it; a word of ours never starts or ends with `_`. |
  | `·` outside Catalan | WordPress keeps the middle dot; we treat it as a separator. |
  | Fallback title | WordPress `sanitize_title/2` can return a fallback; we return `{:error, :empty}`. |
  """

  @tags "we do not parse HTML, so a tag name becomes a word"
  @entities "we do not decode HTML entities, so the entity name becomes a word"
  @join "WordPress deletes the character and joins the parts; we break the word there"
  @diacritics "WordPress always writes the ASCII letter; `latin: :keep` keeps the accented letter"

  @cases [
    {"Big <strong>News</strong> today", [], "big-news-today", "big-strong-news-strong-today",
     @tags},
    {"Fish &amp; Chips&nbsp;Bar", [], "fish-chips-bar", "fish-amp-chips-nbsp-bar", @entities},
    {"Fish & Chips", [], "fish-chips", "fish-chips", nil},
    {"Fish&Chips", [], "fishchips", "fish-chips", @join},
    {"caf%c3%a9 au 100% lait", [], "caf%c3%a9-au-100-lait", "caf-c3-a9-au-100-lait",
     "WordPress keeps a valid `%xx` escape and drops a stray `%`; we treat `%` as a separator"},
    {"MiXeD Case TITLE", [], "mixed-case-title", "mixed-case-title", nil},
    {"one          two", [], "one-two", "one-two", nil},
    {"one \n\n\n two", [], "one-two", "one-two", nil},
    {"one----two----three----", [], "one-two-three", "one-two-three", nil},
    {"don't break the space", [], "dont-break-the-space", "dont-break-the-space", nil},
    {"Take – the Dash", [], "take-the-dash", "take-the-dash", nil},
    {"Take — the Dash", [], "take-the-dash", "take-the-dash", nil},
    {"Take\u{2011}the Dash", [], "take-the-dash", "take-the-dash", nil},
    {"¡Hola amigo!", [], "hola-amigo", "hola-amigo", nil},
    {"Really¿", [], "really", "really", nil},
    {"«Quoted title»", [], "quoted-title", "quoted-title", nil},
    {"‹Quoted title›", [], "quoted-title", "quoted-title", nil},
    {"He said “Hello There”", [], "he-said-hello-there", "he-said-hello-there", nil},
    {"He said „Hello There‟", [], "he-said-hello-there", "he-said-hello-there", nil},
    {"Title • Subtitle", [], "title-subtitle", "title-subtitle", nil},
    {"Rights © Reserved ® 20°", [], "rights-reserved-20", "rights-reserved-20", nil},
    {"Brand ™ Name", [], "brand-name", "brand-tm-name",
     "WordPress drops `™`; Unicode compatibility folding turns it into the letters `tm`"},
    {"words by Left/Right", [], "words-by-left-right", "words-by-left-right", nil},
    {"words by Left//Right", [], "words-by-left-right", "words-by-left-right", nil},
    {"//words by Left/-Right", [], "words-by-left-right", "words-by-left-right", nil},
    {"6×7 is 42", [], "6x7-is-42", "6-7-is-42",
     "WordPress writes `×` as `x`; we treat it as a separator"},
    {"āáǎà", [], "aaaa", "aaaa", nil},
    {"āáǎà", [latin: :keep], "aaaa", "āáǎà", @diacritics},
    {"Crème brûlée façon Noël", [], "creme-brulee-facon-noel", "creme-brulee-facon-noel", nil},
    {"Tiếng Việt Đẹp", [], "tieng-viet-dep", "tieng-viet-dep", nil},
    {"Łódź Ærø Œuvre Þing", [], "lodz-aero-oeuvre-thing", "lodz-aero-oeuvre-thing", nil},
    {"Straße", [], "strase", "strase", nil},
    {"Straße Grüße Öl", [language: "de"], "strasse-gruesse-oel", "strasse-gruesse-oel", nil},
    {"Straße", [language: "de-AT"], "strasse", "strasse", nil},
    {"Blåbærsyltetøj", [], "blabaersyltetoj", "blabaersyltetoj", nil},
    {"Blåbærsyltetøj", [language: "da"], "blaabaersyltetoej", "blaabaersyltetoej", nil},
    {"Col·lecció", [language: "ca"], "colleccio", "colleccio", nil},
    {"Col·lecció", [], "col·leccio", "col-leccio",
     "WordPress keeps the middle dot outside Catalan; we treat it as a separator"},
    {"Đorđe Đoković", [language: "sr"], "djordje-djokovic", "djordje-djokovic", nil},
    {"Đorđe", [language: "bs"], "djordje", "djordje", nil},
    {"Đorđe", [], "dorde", "dorde", nil},
    {"Işık Şeker", [language: "tr"], "isik-seker", "isik-seker", nil},
    {"snake_case_name", [], "snake_case_name", "snake_case_name", nil},
    {"snake_case_name", [keep: []], "snake_case_name", "snake-case-name",
     "`keep: []` makes `_` a word break; WordPress always keeps it"},
    {"__init__ method", [], "__init__-method", "init-method",
     "WordPress keeps `_` at the ends of a word; a word of ours never starts or ends with `_`"},
    {"Привет Ελλάδα", [], "привет-ελλάδα", "привет-ελλάδα", nil},
    {"Nonvisible \u{FEFF}in middle", [], "nonvisible-in-middle", "nonvisible-in-middle", nil},
    {"\u{200B}Nonvisible at start", [], "nonvisible-at-start", "nonvisible-at-start", nil},
    {"Nonvisible at end \u{200B}", [], "nonvisible-at-end", "nonvisible-at-end", nil},
    {"Non\u{200E}vis\u{202E}ible \u{200F}in\u{200D} the title", [], "nonvisible-in-the-title",
     "nonvisible-in-the-title", nil},
    {"\u{200B}", [], :empty, :empty, nil},
    {"\u{200C}\u{200D}\u{FEFF}\u{202E}", [], :empty, :empty, nil},
    {"Wide \u{2002} gap", [], "wide-gap", "wide-gap", nil},
    {"Wide\u{2003}gap\u{2028}here\u{202F}now\u{00A0}end", [], "wide-gap-here-now-end",
     "wide-gap-here-now-end", nil},
    {"Wide gap \u{2001} \u{202F}", [], "wide-gap", "wide-gap", nil},
    {"قیمت\u{200C}گذاری ابری", [], "قیمتگذاری-ابری", "قیمتگذاری-ابری", nil},
    {"قیمت\u{200C}گذاری ابری", [zwnj: :separator], "قیمتگذاری-ابری", "قیمت-گذاری-ابری",
     "WordPress always glues the half-space; `zwnj: :separator` makes it a break"},
    {"?!... --", [], "fallback", :empty,
     "WordPress returns the fallback text it was given; we return `{:error, :empty}`"}
  ]

  compat_cases(@cases)
end
