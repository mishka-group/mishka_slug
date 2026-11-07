# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Properties.WordsTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  @moduledoc """
  How words are found and kept: the script allow-list of `:locales`, separators that do not
  matter, and the order of the words.
  """

  alias MishkaSlug.{Scripts, SlugGen}

  @runs 5_000
  @separators String.graphemes(",;:!?-/\\|()[]{}\"@#$%^&*+`·") ++
                [" ", "\t", "\n", "\u00A0", "\u3000", "\u2014"]
  @word_scripts [
    [0x61..0x7A, 0x30..0x39],
    [0x430..0x44F],
    [0x5D0..0x5EA],
    [0x627..0x63F],
    [0x3B1..0x3C9],
    [0x4E00..0x4E80],
    [0xE01..0xE2E]
  ]

  defp words do
    @word_scripts
    |> Enum.map(&string(&1, min_length: 1, max_length: 6))
    |> one_of()
    |> list_of(min_length: 1, max_length: 6)
  end

  defp allowed_script_regex(locales) do
    {:ok, allowed} = Scripts.for_locales(locales)

    names =
      allowed
      |> Enum.map(&(&1 |> Atom.to_string() |> String.capitalize()))
      |> Enum.map(&"\\p{sc=#{&1}}")

    Regex.compile!("\\A[\\p{sc=Common}\\p{sc=Inherited}#{Enum.join(names)}]\\z", "u")
  end

  property "locales keep only letters of their scripts and Latin" do
    check all(
            text <- SlugGen.text(),
            opts <- SlugGen.options(locales: :some),
            max_runs: @runs
          ) do
      with {:ok, slug} <- MishkaSlug.slugify(text, opts) do
        allowed = allowed_script_regex(opts[:locales])

        slug
        |> String.graphemes()
        |> Enum.flat_map(&String.codepoints/1)
        |> Enum.filter(&(&1 =~ ~r/\p{L}/u))
        |> Enum.each(
          &assert(&1 =~ allowed, "#{inspect(&1)} is outside #{inspect(opts[:locales])}")
        )
      end
    end
  end

  property "locales given in any case or with a region give the same slug" do
    check all(
            text <- SlugGen.text(),
            locale <- member_of(~w(fa ar ru el he ja hi th en)),
            region <- member_of(["", "-IR", "_us", "-Latn"]),
            max_runs: @runs
          ) do
      assert MishkaSlug.slugify(text, locales: [locale]) ==
               MishkaSlug.slugify(text, locales: [String.upcase(locale) <> region])
    end
  end

  property "any run of separators between words gives the same slug as one space" do
    check all(
            words <- words(),
            runs <-
              list_of(list_of(member_of(@separators), min_length: 1, max_length: 3), length: 6),
            opts <- SlugGen.options(),
            max_runs: @runs
          ) do
      joined = Enum.join(words, " ")

      spread =
        words
        |> Enum.zip(Enum.map(runs, &Enum.join/1))
        |> Enum.map_join(fn {word, run} -> word <> run end)

      assert MishkaSlug.slugify(joined, opts) == MishkaSlug.slugify(spread, opts)
    end
  end

  property "words of one script keep their order and are lowercased" do
    check all(words <- words(), max_runs: @runs) do
      expected = Enum.map_join(words, "-", &String.downcase/1)
      assert MishkaSlug.slugify(Enum.join(words, " ")) == {:ok, expected}
    end
  end

  property "the slug of a text starts with the slug of its first word" do
    check all(words <- words(), opts <- SlugGen.options(), max_runs: @runs) do
      with {:ok, whole} <-
             MishkaSlug.slugify(Enum.join(words, " "), Keyword.put(opts, :max_length, nil)),
           {:ok, first} <- MishkaSlug.slugify(hd(words), Keyword.put(opts, :max_length, nil)) do
        assert String.starts_with?(whole, first)
      end
    end
  end
end
