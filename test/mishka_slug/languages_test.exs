# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.LanguagesTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Real titles in many scripts keep their own letters, lose only optional marks, and come back
  unchanged when slugged again. Each row is `{case, title, options, slug}`.
  """

  @cases [
    {"Persian title with half-spaces", "قیمت\u{200C}گذاری نرم\u{200C}افزارهای ابری",
     [locales: ["fa"]], "قیمتگذاری-نرمافزارهای-ابری"},
    {"Persian with Arabic keys and digits", "كتاب يك روز ۱۲۳ و ٤٥٦", [language: "fa"],
     "کتاب-یک-روز-۱۲۳-و-٤٥٦"},
    {"Persian harakat", "مُحَمَّد حَسَن", [], "محمد-حسن"},
    {"Persian tatweel", "ســلام", [], "سلام"},
    {"Persian with an English word", "آموزش React در ۱۰ دقیقه", [locales: ["fa"]],
     "آموزش-react-در-۱۰-دقیقه"},
    {"Arabic", "كيف تتعلم البرمجة؟", [language: "ar"], "كيف-تتعلم-البرمجة"},
    {"Arabic presentation forms", "ﷲ ﻡﻻ", [], "الله-ملا"},
    {"Hebrew with niqqud", "שָׁלוֹם עוֹלָם", [], "שלום-עולם"},
    {"Chinese", "你好，世界！", [], "你好-世界"},
    {"Japanese kanji, kana, digits and the long-vowel mark", "東京キャブ乗り場2018年1月 ラーメン", [],
     "東京キャブ乗り場2018年1月-ラーメン"},
    {"Japanese word of Han and kana", "日本語ひらがなカタカナ", [], "日本語ひらがなカタカナ"},
    {"Korean", "안녕하세요 세계", [], "안녕하세요-세계"},
    {"Chinese around a Latin word", "我爱Elixir编程", [], "我爱-elixir-编程"},
    {"Russian", "Привет, мир! ЁЖ", [], "привет-мир-ёж"},
    {"Hindi with virama and vowel signs", "हिन्दी भाषा नमस्ते", [], "हिन्दी-भाषा-नमस्ते"},
    {"Thai with vowel and tone marks", "สวัสดีชาวโลก ไม่ใช่", [], "สวัสดีชาวโลก-ไม่ใช่"},
    {"Turkish with its language", "İSTANBUL Işık ŞEKER", [language: "tr"], "istanbul-ışık-şeker"},
    {"Turkish without a language", "İSTANBUL Işık", [], "istanbul-işık"},
    {"German", "Straße über Größe", [], "straße-über-größe"},
    {"Greek with its language", "ΟΔΟΣ Αθήνα", [language: "el"], "οδος-αθήνα"},
    {"Fullwidth Latin and digits", "ＡＢＣ\u{3000}ｈｅｌｌｏ １２３", [], "abc-hello-123"},
    {"English apostrophes", "Conway's Law don’t", [], "conways-law-dont"},
    {"Han from Unicode extension B", "𠀀𠀁 x", [], "𠀀𠀁-x"}
  ]

  for {name, title, opts, slug} <- @cases do
    test "#{name} keeps its script and is idempotent" do
      assert {:ok, unquote(slug)} = MishkaSlug.slugify(unquote(title), unquote(opts))
      assert {:ok, unquote(slug)} = MishkaSlug.slugify(unquote(slug), unquote(opts))
    end
  end
end
