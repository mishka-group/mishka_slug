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
      assert {:ok, "olá"} = MishkaSlug.slugify("Olá", locales: ["pt-BR"])
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
      assert {:ok, "ısık"} = MishkaSlug.slugify("ISIK", language: "tr")
      assert {:ok, "isik"} = MishkaSlug.slugify("ISIK", language: "en")
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
    test "keeps the listed characters inside a word but never at its ends" do
      assert {:ok, "v1.2"} = MishkaSlug.slugify("v1.2 .. ...", keep: ["."])
      assert {:ok, "end"} = MishkaSlug.slugify("end.", keep: ["."])
      assert {:error, :empty} = MishkaSlug.slugify("...", keep: ["."])
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

  test "unknown options raise" do
    assert_raise ArgumentError, fn -> MishkaSlug.slugify("x", separator: "_") end
  end
end
