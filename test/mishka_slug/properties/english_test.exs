# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Properties.EnglishTest do
  use MishkaSlug.CompatCase
  use ExUnitProperties

  @moduledoc """
  English titles, which must slug like they do in every mainstream library.

  The table lists real headline shapes with the slug python-slugify gives (its default, ASCII
  mode) and the slug `MishkaSlug` gives. A row where they differ carries the reason. The
  properties check a plain-English title against a short reference written here: lowercase ASCII
  words joined by one `-`, an apostrophe between two letters removed, everything else a break.
  """

  alias MishkaSlug.SlugGen

  @accents "accented Latin letters stay as typed; python-slugify transliterates them to ASCII"
  @ligature "no transliteration: the letter is only lowercased, python-slugify spells it out"

  @cases [
    {"Hello, World!", [], "hello-world", "hello-world", nil},
    {"Phoenix 1.8 is out", [], "phoenix-1-8-is-out", "phoenix-1-8-is-out", nil},
    {"C++ vs. C#", [], "c-vs-c", "c-vs-c", nil},
    {"10 Tips & Tricks", [], "10-tips-tricks", "10-tips-tricks", nil},
    {"What's new in Elixir 1.20?", [], "whats-new-in-elixir-1-20", "whats-new-in-elixir-1-20",
     nil},
    {"Rock'n'Roll", [], "rocknroll", "rocknroll", nil},
    {"rock 'n' roll", [], "rock-n-roll", "rock-n-roll", nil},
    {"e-mail", [], "e-mail", "e-mail", nil},
    {"A--B", [], "a-b", "a-b", nil},
    {"  spaced  ", [], "spaced", "spaced", nil},
    {"UPPER lower", [], "upper-lower", "upper-lower", nil},
    {"snake_case_name", [], "snake-case-name", "snake-case-name", nil},
    {"CamelCase", [], "camelcase", "camelcase", nil},
    {"file.name.ext", [], "file-name-ext", "file-name-ext", nil},
    {"50% off", [], "50-off", "50-off", nil},
    {"user@example.com", [], "user-example-com", "user-example-com", nil},
    {"https://example.com/path?q=1", [], "https-example-com-path-q-1",
     "https-example-com-path-q-1", nil},
    {"#hashtag", [], "hashtag", "hashtag", nil},
    {"Q&A", [], "q-a", "q-a", nil},
    {"Well — that’s that – really…", [], "well-thats-that-really", "well-thats-that-really", nil},
    {"“Smart” ‘quotes’ don’t", [], "smart-quotes-dont", "smart-quotes-dont", nil},
    {"Wait… what", [], "wait-what", "wait-what", nil},
    {"Café Crème", [], "cafe-creme", "café-crème", @accents},
    {"naïve façade", [], "naive-facade", "naïve-façade", @accents},
    {"Ångström", [], "angstrom", "ångström", @accents},
    {"Straße", [], "strasse", "straße", @accents},
    {"Ærøskøbing", [], "aeroskobing", "ærøskøbing", @accents},
    {"ŒUVRE", [], "oeuvre", "œuvre", @ligature},
    {"İstanbul", [], "istanbul", "istanbul", nil},
    {"ﬁne ﬂour", [], "fine-flour", "fine-flour", nil},
    {"½ cup of tea", [], "1-2-cup-of-tea", "1-2-cup-of-tea", nil},
    {"$100 deal", [], "100-deal", "100-deal", nil},
    {"3.14 is pi", [], "3-14-is-pi", "3-14-is-pi", nil},
    {"Mr. O'Brien's Farm", [], "mr-obriens-farm", "mr-obriens-farm", nil},
    {"x² + y² = z²", [], "x2-y2-z2", "x2-y2-z2", nil},
    {"tel: +1 (555) 123-4567", [], "tel-1-555-123-4567", "tel-1-555-123-4567", nil},
    {"I'm here", [], "im-here", "im-here", nil},
    {"The Quick Brown Fox Jumps Over The Lazy Dog", [],
     "the-quick-brown-fox-jumps-over-the-lazy-dog", "the-quick-brown-fox-jumps-over-the-lazy-dog",
     nil},
    {"Top 10 Elixir libraries of 2026", [], "top-10-elixir-libraries-of-2026",
     "top-10-elixir-libraries-of-2026", nil},
    {"Breaking: Markets fall 3.5% as rates rise", [], "breaking-markets-fall-3-5-as-rates-rise",
     "breaking-markets-fall-3-5-as-rates-rise", nil},
    {"Why I left Rails (and what I learned)", [], "why-i-left-rails-and-what-i-learned",
     "why-i-left-rails-and-what-i-learned", nil},
    {"Ask HN: Who is hiring? (March 2026)", [], "ask-hn-who-is-hiring-march-2026",
     "ask-hn-who-is-hiring-march-2026", nil},
    {"Version 2.0.1-beta.3 released", [], "version-2-0-1-beta-3-released",
     "version-2-0-1-beta-3-released", nil},
    {"Version 2.0.1-beta.3 released", [keep: ["."]], "version-2-0-1-beta-3-released",
     "version-2.0.1-beta.3-released",
     "with `keep: [\".\"]` a dot between two characters of a word stays; the default breaks on it"},
    {"README.md", [], "readme-md", "readme-md", nil},
    {"AT&T's new plan", [], "at-ts-new-plan", "at-ts-new-plan", nil},
    {"1,000 reasons", [], "1000-reasons", "1-000-reasons",
     "a comma is a separator, so the digit groups are separate words"},
    {"Don't Panic!!!", [], "dont-panic", "dont-panic", nil},
    {"---Dashes---everywhere---", [], "dashes-everywhere", "dashes-everywhere", nil},
    {"___underscores___", [], "underscores", "underscores", nil},
    {"Tab\tand\nnewline", [], "tab-and-newline", "tab-and-newline", nil},
    {"HELLO", [language: "en"], "hello", "hello", nil},
    {"Hello World", [locales: ["en"]], "hello-world", "hello-world", nil},
    {"Hello World", [digits: :ascii, zwnj: :separator], "hello-world", "hello-world", nil},
    {"What's up? A lot.", [max_length: 12], "whats-up-a-l", "whats-up-a",
     "only whole words are kept, so the slug stops before a word that does not fit"}
  ]

  compat_cases(@cases)

  defp reference(title, max_length) do
    words =
      title
      |> String.downcase()
      |> then(&Regex.replace(~r/(?<=[a-z])'(?=[a-z])/, &1, ""))
      |> String.split(~r/[^a-z0-9]+/, trim: true)

    case take_words(words, max_length) do
      [] -> {:error, :empty}
      words -> {:ok, Enum.join(words, "-")}
    end
  end

  defp take_words(words, nil), do: words

  defp take_words([first | _] = words, max),
    do: fit(words, max, [], -1) |> first_or_cut(first, max)

  defp take_words([], _max), do: []

  defp fit([], _max, taken, _length), do: Enum.reverse(taken)

  defp fit([word | rest], max, taken, length) do
    length = length + 1 + String.length(word)
    if length <= max, do: fit(rest, max, [word | taken], length), else: Enum.reverse(taken)
  end

  defp first_or_cut([], first, max), do: [String.slice(first, 0, max)]
  defp first_or_cut(taken, _first, _max), do: taken

  defp english_options do
    gen(all(opts <- SlugGen.options(), opts[:language] != "tr", do: Keyword.put(opts, :keep, [])))
  end

  property "a plain English title slugs to lowercase words joined by single hyphens" do
    check all(title <- SlugGen.english_title(), opts <- english_options(), max_runs: 5_000) do
      opts = Keyword.put(opts, :max_length, nil)
      assert MishkaSlug.slugify(title, opts) == reference(title, nil)
    end
  end

  property "a plain English title is cut only between words, as the reference cuts it" do
    check all(
            title <- SlugGen.english_title(),
            max <- integer(1..60),
            max_runs: 3_000
          ) do
      assert MishkaSlug.slugify(title, max_length: max) == reference(title, max)
    end
  end

  property "an English slug has no leading or trailing hyphen, no doubled hyphen and no uppercase" do
    check all(title <- SlugGen.english_title(), max_runs: 3_000) do
      with {:ok, slug} <- MishkaSlug.slugify(title) do
        assert slug =~ ~r/\A[a-z0-9]+(-[a-z0-9]+)*\z/
      end
    end
  end

  property "case does not matter in English" do
    check all(title <- SlugGen.english_title(), max_runs: 3_000) do
      assert MishkaSlug.slugify(String.upcase(title)) ==
               MishkaSlug.slugify(String.downcase(title))
    end
  end
end
