# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Compat.AgentFirstSlugTest do
  use MishkaSlug.CompatCase

  @moduledoc """
  The cases and the stress alphabet of the Rust `agent-first-slug` crate, run against
  `MishkaSlug`.

  Source: https://github.com/agentfirstkit/agent-first-slug, `src/lib.rs` (`mod tests`) and
  `tests/generated_grammar.rs`, MIT. The strings are the crate's; the original column is what
  `slug` returns under the configuration that fits the case: Unicode path segment by default, URL
  path segment where the case keeps a dot, ASCII only where the reason says so.

  Not ported: its configuration structure (delimiter, dot policy, fallbacks, transliteration
  maps) and the CLI.

  | Difference | Why |
  |---|---|
  | Latin inside CJK | The crate keeps `現在的nobody` as one word; we cut at the script change. |
  | Letter numbers | The crate drops `Ⅳ`; Unicode compatibility folding turns it into `iv`. |
  | ASCII-only mode | The crate can drop every non-ASCII letter; we keep the script. |
  | `İ` | The crate keeps a combining dot as a break (`i-stanbul`); we lowercase to `i`. |
  | `.` between letters | The crate keeps only dots between digits; `keep: ["."]` keeps them in any word. |
  """

  @script_cut "the crate keeps Latin and CJK in one word; we cut a word where its script changes"
  @ascii_only "the crate was set to keep ASCII only; we keep the script"

  @cases [
    {"現在的Nobody，未來的Somebody！", [], "現在的nobody-未來的somebody", "現在的-nobody-未來的-somebody",
     @script_cut},
    {"牙好，胃口就好，身体倍儿棒，吃嘛嘛香。", [], "牙好-胃口就好-身体倍儿棒-吃嘛嘛香", "牙好-胃口就好-身体倍儿棒-吃嘛嘛香", nil},
    {"お元気ですか？", [], "お元気ですか", "お元気ですか", nil},
    {"Ubuntu 16.04", [], "ubuntu-16-04", "ubuntu-16-04", nil},
    {"Ubuntu 16.04", [keep: ["."]], "ubuntu-16.04", "ubuntu-16.04", nil},
    {"T.U.S.F.G.E.3.0.8", [keep: ["."]], "t-u-s-f-g-e-3.0.8", "t.u.s.f.g.e.3.0.8",
     "the crate keeps only dots between digits; `keep: [\".\"]` keeps a dot inside any word"},
    {".18 increased ! ", [keep: ["."]], "18-increased", "18-increased", nil},
    {"Cafe 世界 42", [], "cafe-42", "cafe-世界-42", @ascii_only},
    {"Hello 世界", [], "hello", "hello-世界", @ascii_only},
    {"Chapter \u{2163}", [], "chapter", "chapter-iv",
     "the crate keeps letters and decimal digits only; `Ⅳ` folds to the letters `iv`"},
    {"\u{0130}stanbul", [], "i-stanbul", "istanbul",
     "the crate splits at the combining dot of `İ`; we lowercase it to a plain `i`"},
    {"!!!", [], :empty, :empty, nil}
  ]

  compat_cases(@cases)

  @alphabet String.graphemes("aA1.. -_İ١٢\u{301}\u{E48}ไมन्\u{93E}ǅßẞΣ\u{345}ΐ")
  @option_sets [
    [],
    [language: "tr"],
    [language: "el"],
    [keep: [".", "_"]],
    [digits: :ascii],
    [max_length: 1],
    [max_length: 2],
    [max_length: 3],
    [max_length: 5],
    [language: "el", keep: ["."], max_length: 3]
  ]

  test "random strings of marks, digits, sigma, titlecase and dots give a stable safe slug" do
    :rand.seed(:exsss, {1, 2, 3})

    for _ <- 1..4_000 do
      length = :rand.uniform(9) - 1
      input = Enum.map_join(1..length//1, fn _ -> Enum.random(@alphabet) end)

      for opts <- @option_sets do
        case MishkaSlug.slugify(input, opts) do
          {:ok, slug} ->
            assert slug =~ ~r/\A[\p{L}\p{M}\p{Nd}._~-]+\z/u,
                   "#{inspect(input)} -> #{inspect(slug)}"

            refute slug =~ ~r/\A[-._~]|[-._~]\z|--/, "#{inspect(input)} -> #{inspect(slug)}"

            assert MishkaSlug.slugify(slug, opts) == {:ok, slug},
                   "#{inspect(input)} #{inspect(opts)} -> #{inspect(slug)}"

            if opts[:max_length] do
              assert length(String.to_charlist(slug)) <= opts[:max_length]
            end

          {:error, :empty} ->
            :ok
        end
      end
    end
  end
end
