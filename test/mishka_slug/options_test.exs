# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.OptionsTest do
  use ExUnit.Case, async: true

  describe ":locales" do
    test "keeps the site's scripts and Latin, and drops the others" do
      title = "سلام Hello Привет שלום"

      assert {:ok, "سلام-hello"} = MishkaSlug.slugify(title, locales: ["fa", "en"])
      assert {:ok, "hello-привет"} = MishkaSlug.slugify(title, locales: ["ru"])
      assert {:ok, "سلام-hello-привет-שלום"} = MishkaSlug.slugify(title)
    end

    test "a homoglyph outside the site's scripts is dropped, not kept inside the word" do
      assert {:ok, "p-ypal"} = MishkaSlug.slugify("p\u{0430}ypal", locales: ["en"])
    end

    test "Japanese and Korean sites keep their whole family of scripts" do
      assert {:ok, "日本語ひらがなカタカナ"} = MishkaSlug.slugify("日本語ひらがなカタカナ", locales: ["ja"])
      assert {:ok, "한국어漢字"} = MishkaSlug.slugify("한국어漢字", locales: ["ko"])
      assert {:ok, "日本語"} = MishkaSlug.slugify("日本語ひらがな", locales: ["ko"])
    end

    test "a region or script subtag counts as its language" do
      assert {:ok, "你好"} = MishkaSlug.slugify("你好", locales: ["zh-hans"])
      assert {:ok, "olá"} = MishkaSlug.slugify("Olá", locales: ["pt-BR"], latin: :keep)
    end

    test "an unknown language is an error, not a silent allow-all" do
      assert {:error, {:unknown_locale, "xx"}} =
               MishkaSlug.slugify("hello", locales: ["fa", "xx"])
    end

    test "a Persian site folds Arabic letters to Persian, a site that also has Arabic does not" do
      assert {:ok, "کتاب-یک"} = MishkaSlug.slugify("كتاب يك", locales: ["fa", "en"])
      assert {:ok, "كتاب-يك"} = MishkaSlug.slugify("كتاب يك", locales: ["fa", "ar"])
    end
  end

  describe ":language" do
    test "picks the Persian fold over the site's languages" do
      assert {:ok, "کتاب"} = MishkaSlug.slugify("كتاب", language: "fa", locales: ["fa", "ar"])
      assert {:ok, "كتاب"} = MishkaSlug.slugify("كتاب", language: "ar", locales: ["fa"])
    end

    test "picks Turkish lowercasing only for Turkish text" do
      assert {:ok, "ısık"} = MishkaSlug.slugify("ISIK", language: "tr", latin: :keep)
      assert {:ok, "isik"} = MishkaSlug.slugify("ISIK", language: "en", latin: :keep)
    end
  end

  describe ":latin" do
    test ":ascii, the default, drops Latin accents like WordPress" do
      assert {:ok, "cafe-creme"} = MishkaSlug.slugify("Café Crème")
      assert {:ok, "naive-facade-angstrom"} = MishkaSlug.slugify("naïve façade Ångström")
      assert {:ok, "strase-aeroskobing-oeuvre"} = MishkaSlug.slugify("Straße Ærøskøbing Œuvre")
      assert {:ok, "isik"} = MishkaSlug.slugify("ISIK", language: "tr")
    end

    test ":ascii follows the language's own spelling" do
      assert {:ok, "strasse-aerger"} = MishkaSlug.slugify("Straße Ärger", language: "de")
      assert {:ok, "aeroe-aalborg"} = MishkaSlug.slugify("Ærø Ålborg", language: "da")
      assert {:ok, "colleccio"} = MishkaSlug.slugify("Col·lecció", language: "ca")
      assert {:ok, "djokovic"} = MishkaSlug.slugify("Đoković", language: "sr")
      assert {:ok, "djokovic"} = MishkaSlug.slugify("Đoković", language: "bs")
      assert {:ok, "dokovic"} = MishkaSlug.slugify("Đoković")
    end

    test ":ascii changes only Latin letters" do
      assert {:ok, "αθήνα-ёж-שלום"} = MishkaSlug.slugify("Αθήνα Ёж שָׁלוֹם")
      assert {:ok, "हिन्दी-cafe"} = MishkaSlug.slugify("हिन्दी café")
    end

    test ":keep leaves Latin letters as typed" do
      assert {:ok, "café-crème"} = MishkaSlug.slugify("Café Crème", latin: :keep)
      assert {:ok, "straße"} = MishkaSlug.slugify("Straße", language: "de", latin: :keep)
    end

    test "refuses any other value" do
      assert_raise ArgumentError, fn -> MishkaSlug.slugify("x", latin: :translit) end
    end
  end

  describe ":digits" do
    test "keeps digits as typed by default" do
      assert {:ok, "۱۴۰۳-١٢-१२३"} = MishkaSlug.slugify("۱۴۰۳ ١٢ १२३")
    end

    test ":ascii writes every decimal digit system as 0-9" do
      assert {:ok, "1403-12-123-5"} = MishkaSlug.slugify("۱۴۰۳ ١٢ १२३ ๕", digits: :ascii)
    end

    test ":ascii knows every decimal digit Unicode has" do
      digits =
        for cp <- 0..0x10FFFF, cp not in 0xD800..0xDFFF, into: "", do: <<cp::utf8>>

      zeros =
        ~r/\p{Nd}/u
        |> Regex.scan(digits)
        |> List.flatten()
        |> Enum.chunk_every(10)
        |> Enum.map(&Enum.join/1)

      for run <- zeros do
        assert {:ok, "0123456789"} = MishkaSlug.slugify(run, digits: :ascii)
      end
    end
  end

  describe ":zwnj" do
    test "removes the Persian half-space by default and glues the parts" do
      assert {:ok, "میخواهم-کتابها"} = MishkaSlug.slugify("می\u{200C}خواهم کتاب\u{200C}ها")
    end

    test ":separator makes it a word break" do
      assert {:ok, "می-خواهم-کتاب-ها"} =
               MishkaSlug.slugify("می\u{200C}خواهم کتاب\u{200C}ها", zwnj: :separator)
    end
  end

  describe ":mixed_scripts" do
    test ":reject refuses a word that changes script" do
      assert {:error, :mixed_scripts} =
               MishkaSlug.slugify("p\u{0430}ypal", mixed_scripts: :reject)
    end

    test ":reject accepts separate words in different scripts and Japanese families" do
      assert {:ok, "آموزش-react"} = MishkaSlug.slugify("آموزش React", mixed_scripts: :reject)
      assert {:ok, "日本語ひらがな"} = MishkaSlug.slugify("日本語ひらがな", mixed_scripts: :reject)
    end
  end

  describe ":keep" do
    test "keeps `_` inside a word by default, like WordPress" do
      assert {:ok, "snake_case_name"} = MishkaSlug.slugify("snake_case_name")
      assert {:ok, "__init__-a_b-c"} = MishkaSlug.slugify("__init__ a_b.c")
    end

    test "an empty list makes `_` a word break" do
      assert {:ok, "snake-case-name"} = MishkaSlug.slugify("snake_case_name", keep: [])
    end

    test "keeps the listed characters at a word's ends by default, like WordPress" do
      assert {:ok, "v1.2-..-..."} = MishkaSlug.slugify("v1.2 .. ...", keep: ["."])
      assert {:ok, "end."} = MishkaSlug.slugify("end.", keep: ["."])
      assert {:ok, "~tilde~"} = MishkaSlug.slugify("~tilde~", keep: ["~"])
    end

    test "a slug that is only `.` or `..` is refused" do
      assert {:error, :empty} = MishkaSlug.slugify(".", keep: ["."])
      assert {:error, :empty} = MishkaSlug.slugify("..", keep: ["."])
      assert {:error, :empty} = MishkaSlug.slugify("..", keep: ["."], trim_kept: true)
      assert {:error, :empty} = MishkaSlug.slugify("...", keep: ["."], trim_kept: true)
    end

    test "a cut that leaves only dots is refused" do
      assert {:error, :empty} = MishkaSlug.slugify("..a", keep: ["."], max_length: 2)
    end
  end

  describe ":trim_kept" do
    test "false keeps `_` at the ends of a word, like WordPress" do
      assert {:ok, "__init__"} = MishkaSlug.slugify("__init__")
      assert {:ok, "_draft-post"} = MishkaSlug.slugify("_draft post")
      assert {:ok, "my_post_"} = MishkaSlug.slugify("my_post_")
      assert {:ok, "_-_-_"} = MishkaSlug.slugify("_ _ _")
      assert {:ok, "_-_-_"} = MishkaSlug.slugify("_-_-_")
    end

    test "true removes kept characters at the ends of a word" do
      assert {:ok, "init"} = MishkaSlug.slugify("__init__", trim_kept: true)
      assert {:ok, "draft-post"} = MishkaSlug.slugify("_draft post", trim_kept: true)
      assert {:ok, "my_post"} = MishkaSlug.slugify("my_post_", trim_kept: true)
      assert {:error, :empty} = MishkaSlug.slugify("_ _ _", trim_kept: true)
      assert {:ok, "end"} = MishkaSlug.slugify("end.", keep: ["."], trim_kept: true)
    end

    test "true removes a kept character glued to a prepended sign and keeps the sign" do
      opts = [keep: ["."], trim_kept: true]

      for {title, slug} <- [
            {"\u{0D4E}.", "\u{0D4E}"},
            {"\u{0D4E}.\u{0D4E}.", "\u{0D4E}.\u{0D4E}"}
          ] do
        assert MishkaSlug.slugify(title, opts) == {:ok, slug}
        assert MishkaSlug.slugify(slug, opts) == {:ok, slug}
      end

      assert {:ok, "\u{0D4E}."} = MishkaSlug.slugify("\u{0D4E}.", keep: ["."])
    end

    test "must be a boolean" do
      assert_raise ArgumentError, fn -> MishkaSlug.slugify("x", trim_kept: "yes") end
    end

    test "refuses characters that are not safe in a URL" do
      for char <- ["?", "!", "/", "#", "%", "-", "@"] do
        assert_raise ArgumentError, fn ->
          MishkaSlug.slugify("x", keep: [char])
        end
      end
    end
  end

  describe ":max_length" do
    test "keeps whole words that fit, counted in code points" do
      {:ok, slug} = MishkaSlug.slugify(String.duplicate("کلمه ", 200), max_length: 50)

      assert String.length(slug) == 49
      assert slug |> String.split("-") |> Enum.all?(&(&1 == "کلمه"))
    end

    test "cuts a first word that is too long between two graphemes" do
      assert {:ok, "हि"} = MishkaSlug.slugify("हिन्दीभाषानमस्ते", max_length: 5)
      assert {:ok, "abc"} = MishkaSlug.slugify("abcdef ghi", max_length: 3)
    end

    test "gives no slug when not even one grapheme fits" do
      assert {:error, :empty} = MishkaSlug.slugify("न्दी", max_length: 1)
    end

    test "a cut slug is idempotent" do
      for max <- 1..20 do
        case MishkaSlug.slugify("हिन्दी भाषा v1.2.3 東京", max_length: max, keep: ["."]) do
          {:ok, slug} ->
            assert {:ok, ^slug} = MishkaSlug.slugify(slug, max_length: max, keep: ["."])

          {:error, reason} ->
            assert reason == :empty
        end
      end
    end
  end

  describe ":separator" do
    test "joins the words of every script" do
      assert {:ok, "سلام_دنیا"} = MishkaSlug.slugify("سلام دنیا", separator: "_")
      assert {:ok, "hello.world"} = MishkaSlug.slugify("Hello World", separator: ".")
      assert {:ok, "привет--мир"} = MishkaSlug.slugify("Привет, мир!", separator: "--")
      assert {:ok, "東京~タワー"} = MishkaSlug.slugify("東京 タワー", separator: "~")
    end

    test "is a word break even when :keep lists it" do
      assert {:ok, "snake_case_title"} = MishkaSlug.slugify("snake_case title", separator: "_")
      assert {:ok, "init"} = MishkaSlug.slugify("__init__", separator: "_")
      assert {:ok, "v1.2_x"} = MishkaSlug.slugify("v1.2 x", separator: "_", keep: ["."])
    end

    test "a zwnj break gets the separator" do
      assert {:ok, "قیمت_گذاری"} =
               MishkaSlug.slugify("قیمت\u200Cگذاری", separator: "_", zwnj: :separator)
    end

    test "is counted in max_length" do
      assert {:ok, "aa--bb"} = MishkaSlug.slugify("aa bb cc", separator: "--", max_length: 7)
      assert {:ok, "aa-bb"} = MishkaSlug.slugify("aa bb cc", max_length: 7)
    end

    test "a slug made with it slugs again to itself" do
      for separator <- ["_", ".", "~", "--"], keep <- [[], ["_"], ["."]] do
        opts = [separator: separator, keep: keep]
        {:ok, slug} = MishkaSlug.slugify("snake_case کتاب v1.2 Hello", opts)
        assert {:ok, ^slug} = MishkaSlug.slugify(slug, opts)
      end
    end

    test "refuses what is not URL-safe or is empty" do
      for separator <- ["/", " ", "", "-/", "%", :_] do
        assert_raise ArgumentError, ~r/separator/, fn ->
          MishkaSlug.slugify("a b", separator: separator)
        end
      end
    end
  end

  describe ":truncate" do
    test "is :max_length by ash_slug's name, with the same cut" do
      for title <- ["What's up? A lot.", "یک دو سه چهار پنج", "हिन्दी भाषा"], max <- 1..12 do
        assert MishkaSlug.slugify(title, truncate: max) ==
                 MishkaSlug.slugify(title, max_length: max)
      end
    end

    test "comes back from validation as :max_length" do
      assert {:ok, opts} = MishkaSlug.Options.validate(truncate: 30)
      assert opts[:max_length] == 30
      refute Keyword.has_key?(opts, :truncate)
    end

    test "with :max_length too is an invalid option" do
      assert {:error, message} = MishkaSlug.Options.validate(max_length: 10, truncate: 20)
      assert message =~ "not both"
      assert_raise ArgumentError, fn -> MishkaSlug.slugify("a", max_length: 1, truncate: 1) end
    end
  end

  test "unknown options raise" do
    assert_raise ArgumentError, fn -> MishkaSlug.slugify("x", ignore: ["."]) end
  end
end
