# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug do
  @moduledoc """
  URL slugs that keep the original script.

  `slugify/2` turns a title into a slug in its own writing system: Persian stays Persian, Hindi
  stays Hindi, Japanese stays Japanese. Only Latin letters change: they lose their accents the
  way WordPress writes them (`Café` gives `cafe`), unless `latin: :keep`.

      iex> MishkaSlug.slugify("قیمت\u{200C}گذاری نرم\u{200C}افزار")
      {:ok, "قیمتگذاری-نرمافزار"}

      iex> MishkaSlug.slugify("हिन्दी भाषा")
      {:ok, "हिन्दी-भाषा"}

      iex> MishkaSlug.slugify("😀🚀")
      {:error, :empty}

  ## What a slug is made of

  A slug is lowercase words joined by `-`. A word is a run of letters and decimal digits, with the
  combining marks that complete them (Hindi vowel signs and viramas, Thai tone marks). Everything
  else, from spaces and punctuation to emoji and `/ ? # % \\ :`, separates words. The result is
  NFC, so a stored slug compares equal to a pasted one (Hangul jamo are composed even after a
  prepended sign such as Tulu-Tigalari `U+113D1`, which OTP's normalizer leaves decomposed).
  Latin letters lose their accents the way WordPress writes them (`Café Crème` gives
  `cafe-creme`, see `:latin`), an apostrophe inside a word is removed (`don't` gives `dont`),
  `_` stays inside a word (`snake_case` gives `snake_case`, see `:keep`), and `.`, `&` and `,`
  separate words (`Q&A` gives `q-a`, `1,000` gives `1-000`). A capital sigma that ends a Greek word becomes `ς`
  (`ΟΔΟΣ` gives `οδος`) in every language but `tr` and `az`.

  ## Safety

  These are always on:

  - Invisible characters are removed, never turned into a break: zero-width spaces and joiners,
    bidi controls (`U+202E` and the isolates), soft hyphens, byte-order marks, variation selectors,
    controls, private-use and unassigned code points. So `pay\\u200Bpal` gives `paypal`.
  - A word may not mix scripts (see `:mixed_scripts`).
  - The slug can never hold a URL delimiter or be `.` or `..`.
  - Arabic harakat, tatweel and Hebrew points are dropped (they are optional spelling); every other
    mark is kept, because in Indic and Thai scripts the marks spell the word.

  ## Idempotent

  `slugify(slug, opts)` returns `{:ok, slug}` for every slug it made with the same options. A CMS
  can therefore re-slug an incoming URL parameter: when the result differs, redirect to it.

  ## Options

  Options are checked by `MishkaSlug.Options`: an unknown option, or a value outside the accepted
  ones, raises `ArgumentError`.

    * `:language` - `String.t() | nil`, default `nil`. The language of the text, such as a page's
      `language` (`"fa"`, `"tr"`). It picks the lowercasing rules (`tr` and `az` turn `I` into
      `ı`), for `fa`, `ur` and `ckb`, folds the Arabic `ي ى ك` into the Persian `ی ک`, and for
      `de`, `da`, `ca`, `sr` and `bs` picks how `latin: :ascii` spells their letters.

    * `:locales` - `[String.t()]`, default `[]`. The site's languages (`["fa", "en"]`). Only
      letters of their scripts, and Latin, are kept; see `MishkaSlug.Scripts`. `[]` keeps every
      script. Without a `:language`, a Persian-family locale without `ar` turns on the Persian
      fold.

    * `:mixed_scripts` - `:split | :reject`, default `:split`. What happens to a word that
      changes script, like `pаypal` with a Cyrillic `а`: `:split` cuts it at the change,
      `:reject` returns `{:error, :mixed_scripts}`.

    * `:zwnj` - `:remove | :separator`, default `:remove`. The Persian half-space (U+200C):
      `:remove` glues the parts (`قیمتگذاری`), `:separator` makes it a word break
      (`قیمت-گذاری`).

    * `:digits` - `:keep | :ascii`, default `:keep`. `:keep` leaves digits as typed (`۱۴۰۳`);
      `:ascii` writes every decimal digit as `0-9` (`1403`).

    * `:latin` - `:ascii | :keep`, default `:ascii`. What happens to accented Latin letters.
      `:ascii` writes them as WordPress's `remove_accents` does: a letter is decomposed and its
      marks dropped (`é` gives `e`, Vietnamese `ệ` gives `e`), and the letters that do not
      decompose get a plain spelling (`ß` gives `s`, `æ` `ae`, `ø` `o`, `þ` `th`, `ł` `l`, `ı`
      `i`). The `:language` adds its own spelling: `de` writes `ä ö ü ß` as `ae oe ue ss`, `da`
      writes `æ ø å` as `ae oe aa`, `ca` joins `l·l` into `ll`, and `sr` and `bs` write `đ` as
      `dj`. Only Latin letters change: Greek, Cyrillic, Arabic and every other script keep their
      marks. `:keep` leaves Latin letters as typed (`Café` gives `café`).

    * `:keep` - list of `"."`, `"_"` and `"~"`, default `["_"]`. Characters kept inside a word
      (`["."]` keeps `v1.2`). Only the URL-safe `.`, `_` and `~` are accepted. They never start
      or end a word: `__init__` gives `init`. By default `_` is kept like WordPress and Django
      keep it (`snake_case_name`); `keep: []` makes it a word break again (`snake-case-name`).
      The list replaces the default, so `keep: ["."]` breaks on `_`; write `[".", "_"]` to keep
      both.

    * `:max_length` - `pos_integer() | nil`, default `nil`. The longest slug, in code points
      (what Postgres and Ash count). Whole words are kept while they fit; a first word that is
      too long is cut between two graphemes.
  """

  alias MishkaSlug.{Options, Scripts}

  @typedoc "Why no slug could be made."
  @type reason :: :empty | :invalid_utf8 | :mixed_scripts | {:unknown_locale, String.t()}

  @persian_family ~w(fa ur ckb)

  @invisible ~r/[\p{Cc}\p{Cf}\p{Co}\p{Cn}\p{Cs}\p{Bidi_Control}\p{Default_Ignorable_Code_Point}]/u
  @whitespace ~r/\p{White_Space}/u
  @optional_marks ~r/[\x{0640}\x{064B}-\x{065F}\x{0670}\x{06D6}-\x{06DC}\x{06DF}-\x{06E4}\x{06E7}\x{06E8}\x{06EA}-\x{06ED}\x{0591}-\x{05BD}\x{05BF}\x{05C1}\x{05C2}\x{05C4}\x{05C5}\x{05C7}]/u
  @apostrophe ~r/(?<=\p{L})['\x{2019}](?=\p{L})/u
  @digit ~r/\p{Nd}/u
  @latin ~r/\p{sc=Latin}\p{M}*/u
  @mark ~r/\p{M}/u
  @catalan_dot ~r/l\x{00B7}(?=l)/u

  @latin_letters %{
    "ß" => "s",
    "æ" => "ae",
    "ð" => "d",
    "ø" => "o",
    "þ" => "th",
    "đ" => "d",
    "ħ" => "h",
    "ı" => "i",
    "ĸ" => "k",
    "ł" => "l",
    "ŋ" => "n",
    "œ" => "oe",
    "ŧ" => "t",
    "ə" => "e"
  }

  @latin_languages %{
    "de" => %{"ä" => "ae", "ö" => "oe", "ü" => "ue", "ß" => "ss"},
    "da" => %{"æ" => "ae", "ø" => "oe", "å" => "aa"},
    "sr" => %{"đ" => "dj"},
    "bs" => %{"đ" => "dj"}
  }
  # Workaround for OTP's NFC (`:unicode.characters_to_nfc_binary`, `String.normalize(:nfc)`, seen on
  # OTP 29): it composes per grapheme cluster and only recomposes Hangul when the cluster starts with
  # a leading jamo, so a prepend sign before Korean jamo (U+0600, U+0D4E, U+113D1) leaves the syllable
  # decomposed ("\u{113D1}\u{1109}\u{1162}" stays 3 code points, not "\u{113D1}\u{C0C8}"). This composes
  # the leftover jamo. Korean only, other scripts compose correctly. Fixed upstream
  # (https://github.com/erlang/otp/issues/11889): remove once the lib requires an OTP with the fix.
  @jamo ~r/[\x{1100}-\x{1112}][\x{1161}-\x{1175}][\x{11A8}-\x{11C2}]?|[\x{AC00}-\x{D7A3}][\x{11A8}-\x{11C2}]/u

  @digit_zeros for(cp <- 0..0x10FFFF, cp not in 0xD800..0xDFFF, into: "", do: <<cp::utf8>>)
               |> then(&Regex.scan(~r/\p{Nd}/u, &1))
               |> List.flatten()
               |> Enum.map(fn <<cp::utf8>> -> cp end)
               |> Enum.chunk_every(10)
               |> Enum.map(&hd/1)

  @doc """
  Makes a slug from `text`.

  Returns `{:ok, slug}`, or `{:error, reason}` when nothing is left (`:empty`), the text is not
  UTF-8 (`:invalid_utf8`), a word mixes scripts under `mixed_scripts: :reject`, or a locale is not
  known (`{:unknown_locale, code}`). Invalid options raise `ArgumentError`.

      iex> MishkaSlug.slugify("كتاب يك ۱۲۳", language: "fa", digits: :ascii)
      {:ok, "کتاب-یک-123"}

      iex> MishkaSlug.slugify("آموزش React در ۱۰ دقیقه", locales: ["fa"])
      {:ok, "آموزش-react-در-۱۰-دقیقه"}
  """
  @spec slugify(String.t(), keyword()) :: {:ok, String.t()} | {:error, reason()}
  def slugify(text, opts \\ []) when is_binary(text) do
    opts = Options.validate!(opts)

    with :ok <- utf8(text),
         {:ok, allowed} <- Scripts.for_locales(opts[:locales]),
         {:ok, words} <- text |> clean(opts) |> words(opts[:keep]) |> split(allowed, opts) do
      words
      |> truncate(opts[:max_length], opts[:keep])
      |> finish()
    end
  end

  @doc """
  Same as `slugify/2`, but returns the slug or raises `ArgumentError`.

      iex> MishkaSlug.slugify!("Привет, мир!")
      "привет-мир"
  """
  @spec slugify!(String.t(), keyword()) :: String.t()
  def slugify!(text, opts \\ []) do
    case slugify(text, opts) do
      {:ok, slug} -> slug
      {:error, reason} -> raise ArgumentError, "cannot make a slug: #{inspect(reason)}"
    end
  end

  defp utf8(text), do: if(String.valid?(text), do: :ok, else: {:error, :invalid_utf8})

  defp clean(text, opts) do
    text
    |> String.normalize(:nfkc)
    |> zwnj(opts[:zwnj])
    |> String.replace(@whitespace, " ")
    |> lowercase(language(opts))
    |> String.normalize(:nfkc)
    |> String.replace(@invisible, "")
    |> fold(fold?(opts))
    |> String.replace(@optional_marks, "")
    |> digits(opts[:digits])
    |> String.replace(@apostrophe, "")
    |> latin(opts[:latin], language(opts))
    |> nfc()
  end

  defp language(opts), do: opts[:language] && Scripts.language(opts[:language])

  defp latin(text, :keep, _language), do: text

  defp latin(text, :ascii, language) do
    letters = Map.merge(@latin_letters, Map.get(@latin_languages, language, %{}))

    text
    |> catalan(language)
    |> String.replace(@latin, &ascii_letter(&1, letters))
  end

  defp catalan(text, "ca"), do: String.replace(text, @catalan_dot, "l")
  defp catalan(text, _language), do: text

  defp ascii_letter(letter, letters) do
    case Map.fetch(letters, String.normalize(letter, :nfc)) do
      {:ok, ascii} ->
        ascii

      :error ->
        letter
        |> String.normalize(:nfd)
        |> String.replace(@mark, "")
        |> String.replace(Map.keys(letters), &Map.fetch!(letters, &1))
    end
  end

  defp nfc(text) do
    text
    |> String.normalize(:nfc)
    |> String.replace(@jamo, &compose_jamo/1)
  end

  defp compose_jamo(<<lead::utf8, vowel::utf8, rest::binary>>) when lead in 0x1100..0x1112,
    do:
      compose_jamo(<<0xAC00 + (lead - 0x1100) * 588 + (vowel - 0x1161) * 28::utf8, rest::binary>>)

  defp compose_jamo(<<syllable::utf8, trail::utf8>>) when rem(syllable - 0xAC00, 28) == 0,
    do: <<syllable + trail - 0x11A7::utf8>>

  defp compose_jamo(text), do: text

  defp zwnj(text, :remove), do: text
  defp zwnj(text, :separator), do: String.replace(text, "\u{200C}", " ")

  defp lowercase(text, language) when language in ["tr", "az"], do: String.downcase(text, :turkic)

  defp lowercase(text, _language),
    do: text |> String.replace("İ", "i") |> String.downcase(:greek)

  defp fold?(opts) do
    case {opts[:language], Enum.map(opts[:locales], &Scripts.language/1)} do
      {nil, languages} -> "ar" not in languages and Enum.any?(languages, &(&1 in @persian_family))
      {language, _} -> Scripts.language(language) in @persian_family
    end
  end

  defp fold(text, false), do: text

  defp fold(text, true) do
    text
    |> String.replace(["ي", "ى"], "ی")
    |> String.replace("ك", "ک")
  end

  defp digits(text, :keep), do: text
  defp digits(text, :ascii), do: Regex.replace(@digit, text, &ascii_digit/1)

  defp ascii_digit(<<cp::utf8>> = digit) do
    case Enum.find(@digit_zeros, &(cp >= &1 and cp < &1 + 10)) do
      nil -> digit
      zero -> <<?0 + cp - zero>>
    end
  end

  defp words(text, keep) do
    "[\\p{L}\\p{Nd}][\\p{L}\\p{M}\\p{Nd}#{Enum.map_join(keep, &Regex.escape/1)}]*"
    |> Regex.compile!("u")
    |> Regex.scan(text)
    |> List.flatten()
  end

  defp split(words, allowed, opts) do
    Enum.reduce_while(words, {:ok, []}, fn word, {:ok, acc} ->
      case Scripts.split(word, allowed, opts[:mixed_scripts]) do
        {:ok, parts} -> {:cont, {:ok, acc ++ Enum.map(parts, &trim(&1, opts[:keep]))}}
        error -> {:halt, error}
      end
    end)
  end

  defp trim(word, []), do: word

  defp trim(word, keep) do
    kept? = &String.starts_with?(&1, keep)

    word
    |> String.graphemes()
    |> Enum.drop_while(kept?)
    |> Enum.reverse()
    |> Enum.drop_while(kept?)
    |> Enum.reverse()
    |> Enum.join()
  end

  defp truncate(words, nil, _keep), do: words

  defp truncate([first | _] = words, max, keep) do
    words
    |> Enum.reduce_while({[], -1}, fn word, {acc, length} ->
      length = length + 1 + codepoints(word)
      if length <= max, do: {:cont, {[word | acc], length}}, else: {:halt, {acc, length}}
    end)
    |> case do
      {[], _} -> [first |> cut(max) |> trim(keep)]
      {taken, _} -> Enum.reverse(taken)
    end
  end

  defp truncate([], _max, _keep), do: []

  defp cut(word, max) do
    word
    |> String.graphemes()
    |> Enum.reduce_while({"", 0}, fn grapheme, {acc, length} ->
      length = length + codepoints(grapheme)
      if length <= max, do: {:cont, {acc <> grapheme, length}}, else: {:halt, {acc, length}}
    end)
    |> elem(0)
  end

  defp codepoints(text), do: text |> String.to_charlist() |> length()

  defp finish(words) do
    case Enum.reject(words, &(&1 == "")) do
      [] -> {:error, :empty}
      words -> {:ok, Enum.join(words, "-")}
    end
  end
end
