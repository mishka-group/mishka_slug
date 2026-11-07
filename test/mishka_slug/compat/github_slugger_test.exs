# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Compat.GithubSluggerTest do
  use MishkaSlug.CompatCase

  @moduledoc """
  The fixtures of github-slugger, run against `MishkaSlug`.

  Source: https://github.com/Flet/github-slugger, `test/fixtures.json`, ISC. The strings are the
  project's; the original column is the slug GitHub gives a heading, as the fixture lists it.

  Not ported: the repeat counters (`alpha`, `alpha-1`), which depend on the headings seen before,
  and the `maintainCase` option. The long per-category fixtures (`Format`, `Private_Use`, ...) are
  covered by the sweep over every code point at the end of this file.

  | Difference | Why |
  |---|---|
  | Edges and runs | GitHub keeps one `-` for every space, dash or removed symbol; we join with one. |
  | `_`, `.` | GitHub keeps `_` and deletes `.`; we break the word at both unless `keep` says otherwise. |
  | `–` | GitHub deletes the en and em dash and joins the parts; we break the word. |
  | `__proto__` | GitHub keeps the underscores; we do not start a slug with `_`. |
  """

  @runs "GitHub keeps one hyphen per space or symbol; we join any run with one"
  @edges "GitHub keeps a hyphen at the edge; we never start or end a slug with one"
  @underscore "GitHub keeps `_`; we break the word there unless `keep: [\"_\"]`"
  @dot "GitHub deletes `.` and joins the parts; we break the word"

  @cases [
    {"alpha", [], "alpha", "alpha", nil},
    {"bravoCharlieDelta", [], "bravocharliedelta", "bravocharliedelta", nil},
    {"hasOwnProperty", [], "hasownproperty", "hasownproperty", nil},
    {"__proto__", [], "__proto__", "proto", "a slug does not start or end with `_`"},
    {"echo 1", [], "echo-1", "echo-1", nil},
    {"foxtrot-1", [], "foxtrot-1", "foxtrot-1", nil},
    {"heading with a - dash", [], "heading-with-a---dash", "heading-with-a-dash", @runs},
    {"heading with an _ underscore", [], "heading-with-an-_-underscore",
     "heading-with-an-underscore", @underscore},
    {"heading with a period.txt", [], "heading-with-a-periodtxt", "heading-with-a-period-txt",
     @dot},
    {"heading with a period.txt", [keep: ["."]], "heading-with-a-periodtxt",
     "heading-with-a-period.txt", @dot},
    {"exchange.bind_headers(exchange, routing [, bindCallback])", [],
     "exchangebind_headersexchange-routing--bindcallback",
     "exchange-bind-headers-exchange-routing-bindcallback", @dot},
    {" ", [], "-", :empty, "GitHub gives `-` for a blank heading; we have no slug"},
    {" a", [], "-a", "a", @edges},
    {"a ", [], "a-", "a", @edges},
    {" a ", [], "-a-", "a", @edges},
    {"-a-", [], "-a--1", "a", @edges},
    {"apostrophe’s should be trimmed", [], "apostrophes-should-be-trimmed",
     "apostrophes-should-be-trimmed", nil},
    {"I ♥ unicode", [], "i--unicode", "i-unicode", @runs},
    {"dash-dash", [], "dash-dash", "dash-dash", nil},
    {"en–dash", [], "endash", "en-dash", @dot},
    {"em–dash", [], "emdash", "em-dash", @dot},
    {"😄 unicode emoji", [], "-unicode-emoji", "unicode-emoji", @edges},
    {"😄-😄 unicode emoji", [], "--unicode-emoji", "unicode-emoji", @edges},
    {"😄_😄 unicode emoji", [], "_-unicode-emoji", "unicode-emoji", @edges},
    {"😄 - an emoji", [], "---an-emoji", "an-emoji", @edges},
    {":smile: - a gemoji", [], "smile---a-gemoji", "smile-a-gemoji", @runs},
    {"Привет", [], "привет", "привет", nil},
    {"Профили пользователей", [], "профили-пользователей", "профили-пользователей", nil},
    {"Привет non-latin 你好", [], "привет-non-latin-你好", "привет-non-latin-你好", nil},
    {":ok: No underscore", [], "ok-no-underscore", "ok-no-underscore", nil},
    {":ok_hand: Single", [], "ok_hand-single", "ok-hand-single", @underscore},
    {":ok_hand: Single", [keep: ["_"]], "ok_hand-single", "ok_hand-single", nil},
    {":ok_hand::hatched_chick: Two in a row with no spaces", [],
     "ok_handhatched_chick-two-in-a-row-with-no-spaces",
     "ok-hand-hatched-chick-two-in-a-row-with-no-spaces",
     "GitHub joins the two names; we break at `:` and `_`"},
    {"a\u{2028}b", [], "ab", "a-b", "GitHub deletes the line separator; we break the word"},
    {"a\u{2029}b", [], "ab-1", "a-b",
     "GitHub deletes the paragraph separator; we break the word"},
    {"a\u{00A0}\u{2000}\u{3000}b", [], "a---b", "a-b", @runs},
    {"a- ‐ ‑ ‒ — ― 〜 ﹣ －b", [], "a---------b", "a-b", @runs},
    {"a« ‘ “ ‹b", [], "a----b", "a-b", @runs},
    {"a‿ ⁀ ＿b", [], "a-_-b", "a-b", @runs}
  ]

  compat_cases(@cases)

  test "every code point leaves only letters, marks, digits and hyphens, and re-slugs to itself" do
    allowed = ~r/\A[\p{L}\p{M}\p{Nd}-]+\z/u

    chunks =
      for cp <- 0..0x10FFFF, cp not in 0xD800..0xDFFF, do: <<cp::utf8>>

    for chunk <- Enum.chunk_every(chunks, 64) do
      title = "a " <> Enum.join(chunk, " ") <> " b"

      assert {:ok, slug} = MishkaSlug.slugify(title)
      assert slug =~ allowed
      assert {:ok, ^slug} = MishkaSlug.slugify(slug)
    end
  end
end
