# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Scripts do
  @moduledoc """
  The writing systems of letters and of a site's languages.

  `MishkaSlug.slugify/2` uses it for two rules:

  - **Allow-list.** A site's languages (`locales: ["fa", "en"]`) become the scripts a slug may
    use (`[:arabic, :latin]`). Latin is always allowed, because English words and brand names
    appear in every language. A letter of any other script is dropped.
  - **One script per word.** A word that changes script, like `pаypal` with a Cyrillic `а`, is cut
    at the change or refused. Japanese (Han with Hiragana and Katakana), Korean (Han with Hangul)
    and Chinese with Bopomofo are one family each, so they are never cut. All the scripts of a
    part must fit one family: `夏の幻ㄒㄧㄤ` is cut before the Bopomofo, because Han carries
    Hiragana in from the start and no family holds Hiragana with Bopomofo.

  A combining mark belongs to the letter before it and is dropped with it, so a dropped letter
  never leaves its mark behind. Digits and letters that belong to no single script (such as the
  Japanese long-vowel mark `ー`) are neutral: they stay with the letters around them. A letter of a script
  this module does not know by name (for example Tibetan) counts as `:other`.
  """

  @pcre_names %{
    latin: "Latin",
    arabic: "Arabic",
    hebrew: "Hebrew",
    cyrillic: "Cyrillic",
    greek: "Greek",
    armenian: "Armenian",
    georgian: "Georgian",
    han: "Han",
    hiragana: "Hiragana",
    katakana: "Katakana",
    hangul: "Hangul",
    bopomofo: "Bopomofo",
    devanagari: "Devanagari",
    bengali: "Bengali",
    gujarati: "Gujarati",
    gurmukhi: "Gurmukhi",
    kannada: "Kannada",
    malayalam: "Malayalam",
    sinhala: "Sinhala",
    tamil: "Tamil",
    telugu: "Telugu",
    thai: "Thai",
    lao: "Lao",
    khmer: "Khmer",
    myanmar: "Myanmar",
    ethiopic: "Ethiopic"
  }

  @scripts Map.keys(@pcre_names)

  @runs Regex.compile!(
          "([\\p{Nd}\\p{M}\\p{sc=Common}\\p{sc=Inherited}]+)|" <>
            Enum.map_join(@scripts, "|", &"((?:\\p{sc=#{Map.fetch!(@pcre_names, &1)}}\\p{M}*)+)") <>
            "|(\\p{L}\\p{M}*)",
          "u"
        )

  @groups [:neutral | @scripts] ++ [:other]

  @families [[:han, :hiragana, :katakana], [:han, :hangul], [:han, :bopomofo]]

  @non_latin %{
    "am" => [:ethiopic],
    "ar" => [:arabic],
    "az" => [:cyrillic],
    "be" => [:cyrillic],
    "bg" => [:cyrillic],
    "bn" => [:bengali],
    "ckb" => [:arabic],
    "el" => [:greek],
    "fa" => [:arabic],
    "gu" => [:gujarati],
    "he" => [:hebrew],
    "hi" => [:devanagari],
    "hy" => [:armenian],
    "ja" => [:han, :hiragana, :katakana],
    "ka" => [:georgian],
    "kk" => [:cyrillic],
    "km" => [:khmer],
    "kn" => [:kannada],
    "ko" => [:hangul, :han],
    "ku" => [:arabic],
    "ky" => [:cyrillic],
    "lo" => [:lao],
    "mk" => [:cyrillic],
    "ml" => [:malayalam],
    "mn" => [:cyrillic],
    "mr" => [:devanagari],
    "my" => [:myanmar],
    "ne" => [:devanagari],
    "pa" => [:gurmukhi, :arabic],
    "ps" => [:arabic],
    "ru" => [:cyrillic],
    "sd" => [:arabic, :devanagari],
    "si" => [:sinhala],
    "sr" => [:cyrillic],
    "ta" => [:tamil],
    "te" => [:telugu],
    "tg" => [:cyrillic],
    "th" => [:thai],
    "ug" => [:arabic],
    "uk" => [:cyrillic],
    "ur" => [:arabic],
    "uz" => [:cyrillic],
    "yi" => [:hebrew],
    "zh" => [:han, :bopomofo]
  }

  @latin_only ~w(af bs ca cs cy da de en eo es et eu fi fil fr ga gl ha hr hu id is it lt lv ms mt nb
                 nl no pl pt ro sk sl so sq sv sw tk tr vi yo zu)

  @typedoc "A script a slug may use, as `MishkaSlug.Scripts.for_locales/1` returns it."
  @type script :: atom()

  @doc """
  Returns the scripts the languages of a site are written in, always with `:latin`.

  A locale is a language code as Mishka CMS stores it (`"fa"`, `"pt-br"`, `"zh-hans"`); only the
  language part counts. An empty list means no restriction and returns `:any`.

      iex> MishkaSlug.Scripts.for_locales(["fa", "en"])
      {:ok, [:arabic, :latin]}

      iex> MishkaSlug.Scripts.for_locales(["xx"])
      {:error, {:unknown_locale, "xx"}}
  """
  @spec for_locales([String.t()]) ::
          {:ok, :any | [script()]} | {:error, {:unknown_locale, String.t()}}
  def for_locales([]), do: {:ok, :any}

  def for_locales(locales) do
    Enum.reduce_while(locales, {:ok, []}, fn locale, {:ok, acc} ->
      case scripts_of(language(locale)) do
        {:ok, scripts} -> {:cont, {:ok, acc ++ scripts}}
        :error -> {:halt, {:error, {:unknown_locale, locale}}}
      end
    end)
    |> then(fn
      {:ok, scripts} -> {:ok, Enum.uniq(scripts ++ [:latin])}
      error -> error
    end)
  end

  @doc """
  Returns the language part of a locale code, lowercased: `"pt-BR"` gives `"pt"`.
  """
  @spec language(String.t()) :: String.t()
  def language(locale) do
    [language | _] = locale |> String.downcase() |> String.split(["-", "_"])
    language
  end

  @doc """
  Cuts one word into the parts a slug keeps.

  `allowed` is `:any` or a list from `for_locales/1`. With `:split` the word is cut where its
  script changes and the parts in a script that is not allowed are dropped; with `:reject` a word
  that changes script returns `{:error, :mixed_scripts}`.

      iex> MishkaSlug.Scripts.split("pаypal", :any, :split)
      {:ok, ["p", "а", "ypal"]}

      iex> MishkaSlug.Scripts.split("pаypal", [:latin], :split)
      {:ok, ["p", "ypal"]}
  """
  @spec split(String.t(), :any | [script()], :split | :reject) ::
          {:ok, [String.t()]} | {:error, :mixed_scripts}
  def split(word, allowed, mode) do
    runs = runs(word)

    case {mode, merge(runs, :any)} do
      {:reject, [_, _ | _]} -> {:error, :mixed_scripts}
      {_, parts} when allowed == :any -> {:ok, texts(parts)}
      _ -> {:ok, runs |> merge(allowed) |> texts()}
    end
  end

  defp scripts_of(language) when is_map_key(@non_latin, language),
    do: {:ok, Map.fetch!(@non_latin, language)}

  defp scripts_of(language) when language in @latin_only, do: {:ok, []}
  defp scripts_of(_language), do: :error

  defp runs(word) do
    @runs
    |> Regex.scan(word, capture: :all_but_first)
    |> Enum.map(fn groups ->
      index = Enum.find_index(groups, &(&1 != ""))
      {Enum.at(@groups, index), Enum.at(groups, index)}
    end)
  end

  defp merge(runs, allowed) do
    runs
    |> Enum.map(fn {script, text} -> {block(script, allowed), text} end)
    |> Enum.reduce([], &join/2)
    |> Enum.reverse()
  end

  defp block(:neutral, _allowed), do: :neutral
  defp block(script, :any), do: [script]
  defp block(script, allowed), do: if(script in allowed, do: [script], else: :blocked)

  defp join({:neutral, text}, [{:blocked, _} | _] = acc), do: [{:neutral, text} | acc]
  defp join({:neutral, text}, [{scripts, part} | rest]), do: [{scripts, part <> text} | rest]
  defp join({:blocked, text}, acc), do: [{:blocked, text} | acc]
  defp join({scripts, text}, [{:neutral, part} | rest]), do: [{scripts, part <> text} | rest]

  defp join({[script], text}, [{seen, part} | rest] = acc) do
    case family?(seen, script) do
      true -> [{Enum.uniq([script | seen]), part <> text} | rest]
      false -> [{[script], text} | acc]
    end
  end

  defp join(run, []), do: [run]

  defp family?(:blocked, _script), do: false
  defp family?([script], script), do: true

  defp family?(seen, script),
    do: Enum.any?(@families, fn family -> Enum.all?([script | seen], &(&1 in family)) end)

  defp texts(parts), do: for({script, text} <- parts, script != :blocked, do: text)
end
