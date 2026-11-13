# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Properties.OutputTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  @moduledoc """
  What every slug looks like, for any text and any option combination: the result shape, the
  alphabet, idempotence, normalization independence, casing and the length limit.
  """

  alias MishkaSlug.SlugGen

  @runs 5_000
  @alphabet ~r/\A[\p{L}\p{Nd}][\p{L}\p{M}\p{Nd}]*(-[\p{L}\p{Nd}][\p{L}\p{M}\p{Nd}]*)*\z/u
  @unsafe ~r/[\p{Cc}\p{Cf}\p{Co}\p{Cn}\p{Cs}\p{Z}\p{Bidi_Control}\p{Default_Ignorable_Code_Point}]/u
  @delimiters ~w(/ ? # % \\ < > " ' :) ++ [" "]

  defp slug(text, opts), do: MishkaSlug.slugify(text, opts)

  defp slug_chars(opts), do: Regex.escape(Enum.join(opts[:keep]))

  property "the result is a slug or a reason, and never raises" do
    check all(text <- SlugGen.text(), opts <- SlugGen.options(), max_runs: @runs) do
      case slug(text, opts) do
        {:ok, slug} -> assert is_binary(slug) and slug != ""
        {:error, :empty} -> :ok
        {:error, :no_allowed_script} -> assert opts[:locales] != []
        {:error, :mixed_scripts} -> assert opts[:mixed_scripts] == :reject
      end
    end
  end

  property "text that is not UTF-8 is refused, whatever the options" do
    check all(
            head <- SlugGen.text(),
            tail <- SlugGen.text(),
            bad <- member_of([<<255>>, <<0xC0, 0x80>>, <<0xED, 0xA0, 0x80>>, <<0xE2, 0x82>>]),
            opts <- SlugGen.options(),
            max_runs: @runs
          ) do
      assert slug(head <> bad <> tail, opts) == {:error, :invalid_utf8}
    end
  end

  property "a slug uses only letters, digits, marks and single hyphens" do
    check all(text <- SlugGen.text(), opts <- SlugGen.options(), max_runs: @runs) do
      with {:ok, slug} <- slug(text, opts) do
        keep = slug_chars(opts)

        alphabet =
          Regex.compile!(
            "\\A[\\p{L}\\p{M}\\p{Nd}#{keep}]+(-[\\p{L}\\p{M}\\p{Nd}#{keep}]+)*\\z",
            "u"
          )

        assert slug =~ alphabet
        refute slug =~ @unsafe
        refute String.starts_with?(slug, "-") or String.ends_with?(slug, "-")
        refute slug =~ "--"
        refute slug in [".", ".."]
        refute Enum.any?(@delimiters, &String.contains?(slug, &1))
      end
    end
  end

  property "without :keep every word starts with a letter or digit" do
    check all(
            text <- SlugGen.text(),
            opts <- SlugGen.options(locales: :none),
            opts = Keyword.put(opts, :keep, []),
            max_runs: @runs
          ) do
      with {:ok, slug} <- slug(text, opts), do: assert(slug =~ @alphabet)
    end
  end

  property "trim_kept removes kept characters at word ends; without it a slug is still safe" do
    check all(
            text <- SlugGen.text(),
            opts <- SlugGen.options(locales: :none),
            max_runs: @runs
          ) do
      with {:ok, slug} <- slug(text, Keyword.put(opts, :trim_kept, true)) do
        for word <- String.split(slug, "-"), graphemes = String.graphemes(word) do
          refute String.starts_with?(hd(graphemes), opts[:keep])
          refute String.contains?(List.last(graphemes), opts[:keep])
        end
      end

      with {:ok, kept_slug} <- slug(text, Keyword.put(opts, :trim_kept, false)),
           {:ok, ^kept_slug} <- slug(kept_slug, Keyword.put(opts, :trim_kept, false)) do
        refute kept_slug in [".", ".."]
      end
    end
  end

  property "with locales, no word starts with a combining mark left by a dropped letter" do
    check all(
            text <- SlugGen.text(),
            opts <- SlugGen.options(),
            opts = Keyword.put(opts, :keep, []),
            max_runs: @runs
          ) do
      with {:ok, slug} <- slug(text, opts), do: assert(slug =~ @alphabet)
    end
  end

  property "a slug is valid NFC UTF-8 and survives URI encoding" do
    check all(text <- SlugGen.text(), opts <- SlugGen.options(), max_runs: @runs) do
      with {:ok, slug} <- slug(text, opts) do
        assert String.valid?(slug)
        assert SlugGen.nfc(slug) == slug
        encoded = URI.encode(slug, &URI.char_unreserved?/1)
        assert encoded =~ ~r/\A[A-Za-z0-9\-._~%]+\z/
        assert URI.decode(encoded) == slug
      end
    end
  end

  property "slugging a slug again with the same options gives the same slug" do
    check all(
            text <- SlugGen.text(),
            opts <- SlugGen.options(locales: :none),
            max_runs: @runs * 2
          ) do
      with {:ok, slug} <- slug(text, opts), do: assert(slug(slug, opts) == {:ok, slug})
    end
  end

  property "with a separator and lowercase?: false, a slug is URL-safe and slugs again to itself" do
    check all(
            text <- SlugGen.text(),
            opts <- SlugGen.options(),
            separator <- member_of(["-", "_", ".", "~", "--", "_-"]),
            lowercase? <- boolean(),
            max_runs: @runs * 2
          ) do
      opts = Keyword.merge(opts, separator: separator, lowercase?: lowercase?)

      with {:ok, slug} <- slug(text, opts) do
        refute slug =~ @unsafe
        refute Enum.any?(@delimiters, &String.contains?(slug, &1))
        refute slug in [".", ".."]
        assert String.length(slug) <= (opts[:max_length] || String.length(slug))
        assert slug(slug, opts) == {:ok, slug}
      end
    end
  end

  property "with locales, slugging a slug again gives the same slug" do
    check all(text <- SlugGen.text(), opts <- SlugGen.options(), max_runs: @runs * 2) do
      with {:ok, slug} <- slug(text, opts), do: assert(slug(slug, opts) == {:ok, slug})
    end
  end

  property "with latin: :ascii no Latin letter keeps an accent or an unspelled letter" do
    check all(
            text <- SlugGen.text(),
            opts <- SlugGen.options(),
            opts = Keyword.put(opts, :latin, :ascii),
            max_runs: @runs
          ) do
      with {:ok, slug} <- slug(text, opts) do
        refute slug =~ ~r/\p{sc=Latin}\p{M}/u
        refute String.normalize(slug, :nfd) =~ ~r/\p{sc=Latin}\p{M}/u
        refute String.contains?(slug, ~w(ß æ ð ø þ đ ħ ı ĸ ł ŋ œ ŧ ə))
      end
    end
  end

  property "latin only changes Latin letters: text without any slugs the same either way" do
    check all(
            text <- SlugGen.text(),
            opts <- SlugGen.options(),
            text = text |> String.normalize(:nfkc) |> String.replace(~r/\p{sc=Latin}/u, " "),
            max_runs: @runs
          ) do
      assert slug(text, Keyword.put(opts, :latin, :ascii)) ==
               slug(text, Keyword.put(opts, :latin, :keep))
    end
  end

  property "slugging is deterministic" do
    check all(text <- SlugGen.text(), opts <- SlugGen.options(), max_runs: @runs) do
      assert slug(text, opts) == slug(text, opts)
    end
  end

  property "every Unicode normalization form of the text gives the same slug" do
    check all(text <- SlugGen.text(), opts <- SlugGen.options(), max_runs: @runs) do
      expected = slug(text, opts)

      for form <- [:nfc, :nfd, :nfkc, :nfkd] do
        assert slug(SlugGen.normalize(text, form), opts) == expected
      end
    end
  end

  property "a slug is already lowercase in the language's casing" do
    check all(text <- SlugGen.text(), opts <- SlugGen.options(), max_runs: @runs) do
      with {:ok, slug} <- slug(text, opts) do
        mode = if opts[:language] in ["tr", "az"], do: :turkic, else: :default
        assert String.downcase(slug, mode) == slug
      end
    end
  end

  property "max_length is never exceeded and never cuts a grapheme" do
    check all(
            text <- SlugGen.text(),
            opts <- SlugGen.options(),
            max <- integer(1..40),
            max_runs: @runs * 2
          ) do
      full = slug(text, Keyword.put(opts, :max_length, nil))

      case {slug(text, Keyword.put(opts, :max_length, max)), full} do
        {{:ok, cut}, {:ok, full}} ->
          assert length(String.to_charlist(cut)) <= max
          assert String.starts_with?(full, cut)

          if cut != full and not String.starts_with?(full, cut <> "-") do
            [first | _] = String.split(full, "-")
            refute cut =~ "-"

            assert cut ==
                     first
                     |> String.graphemes()
                     |> Enum.take(String.length(cut))
                     |> Enum.join()
          end

        {{:error, :empty}, {:ok, _}} ->
          :ok

        {same, same} ->
          :ok
      end
    end
  end
end
