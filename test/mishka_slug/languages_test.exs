# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.LanguagesTest do
  use ExUnit.Case, async: true

  @moduledoc """
  Real titles in many scripts keep their own letters, lose only optional marks, and come back
  unchanged when slugged again. Latin letters lose their accents unless `latin: :keep`. Each row
  is `{case, title, options, slug}`.
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
    {"Turkish with its language", "İSTANBUL Işık ŞEKER", [language: "tr"], "istanbul-isik-seker"},
    {"Turkish with its language, accents kept", "İSTANBUL Işık ŞEKER",
     [language: "tr", latin: :keep], "istanbul-ışık-şeker"},
    {"Turkish without a language", "İSTANBUL Işık", [], "istanbul-isik"},
    {"Turkish without a language, accents kept", "İSTANBUL Işık", [latin: :keep],
     "istanbul-işık"},
    {"German", "Straße über Größe", [], "strase-uber-grose"},
    {"German with its language", "Straße über Größe", [language: "de"], "strasse-ueber-groesse"},
    {"German, accents kept", "Straße über Größe", [latin: :keep], "straße-über-größe"},
    {"Danish with its language", "Blåbær Ørsted", [language: "da"], "blaabaer-oersted"},
    {"Catalan with its language", "Col·lecció paral·lela", [language: "ca"],
     "colleccio-parallela"},
    {"Serbian Latin with its language", "Đurđevdan", [language: "sr"], "djurdjevdan"},
    {"Vietnamese", "Tiếng Việt có dấu", [], "tieng-viet-co-dau"},
    {"Vietnamese, accents kept", "Tiếng Việt có dấu", [latin: :keep], "tiếng-việt-có-dấu"},
    {"Polish", "Zażółć gęślą jaźń", [], "zazolc-gesla-jazn"},
    {"Icelandic", "Þórður Ægir", [], "thordur-aegir"},
    {"Greek with its language", "ΟΔΟΣ Αθήνα", [language: "el"], "οδος-αθήνα"},
    {"Greek without a language", "ΟΔΟΣ ΣΟΦΟΣ Σ", [], "οδος-σοφος-σ"},
    {"Greek in an English page", "ΟΔΟΣ Street", [language: "en"], "οδος-street"},
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
