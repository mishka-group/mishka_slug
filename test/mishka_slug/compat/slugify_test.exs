# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Compat.SlugifyTest do
  use MishkaSlug.CompatCase

  @moduledoc """
  The cases of the Elixir `slugify` package, run against `MishkaSlug`.

  Source: https://github.com/jayjun/slugify, `test/slug_test.exs`, MIT. The strings are the
  project's; the original column is what `Slug.slugify/1` returns (`:empty` for its `nil`).

  Not ported: the `separator`, `lowercase` and `ignore` options. `MishkaSlug` always joins with
  `-`. `truncate: n` is `max_length: n`.

  | Difference | Why |
  |---|---|
  | Every script but Latin | `slugify` transliterates to ASCII (`slugify` writes `ni-hao` for Han); we keep the script. |
  | `truncate` | Both stop at a whole word; when the first word is too long `slugify` gives `nil`, we cut it. |
  | Khmer and Lao | The zero-width space between words is removed, not turned into a break. |
  | `_` | `slugify` makes `_` a separator; we keep it inside a word unless `keep: []`. |
  """

  @ascii "slugify writes ASCII for this script; we keep the script's own letters"
  @zero_width "the zero-width space is an invisible character and is removed, not turned into a break"

  @cases [
    {"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789", [],
     "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz0123456789",
     "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz0123456789", nil},
    {"🙅\u{200D}", [], :empty, :empty, nil},
    {"!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~", [], :empty, :empty, nil},
    {"Hello, World!", [], "hello-world", "hello-world", nil},
    {"  Hello,\t World!\n", [], "hello-world", "hello-world", nil},
    {"hello-world", [], "hello-world", "hello-world", nil},
    {"--Hello--World--", [], "hello-world", "hello-world", nil},
    {"__HELLO__WORLD__", [], "hello-world", "hello__world",
     "slugify makes `_` a separator; we keep it inside a word, as WordPress does"},
    {"__HELLO__WORLD__", [keep: []], "hello-world", "hello-world", nil},
    {"test,is a.test", [keep: ["."]], "test-is-a.test", "test-is-a.test", nil},
    {"test,is a.test", [], "test-is-a-test", "test-is-a-test", nil},
    {"It's a small world", [max_length: 5], "its-a", "its-a", nil},
    {"It's a small world", [max_length: 7], "its-a", "its-a", nil},
    {"It's a small world", [max_length: 20], "its-a-small-world", "its-a-small-world", nil},
    {"It's a small world", [max_length: 2], :empty, "it",
     "when the first word is too long slugify gives `nil`; we cut it between two graphemes"},
    {"مرحبا بالعالم", [], "mrhb-blaalm", "مرحبا-بالعالم", @ascii},
    {"ሰላም ልዑል", [], "salaame-leule", "ሰላም-ልዑል", @ascii},
    {"Բարեւ աշխարհ", [], "barew-ashkharh", "բարեւ-աշխարհ", @ascii},
    {"ওহে বিশ্ব", [], "ohe-bishb", "ওহে-বিশ্ব", @ascii},
    {"မင်္ဂလာပါကမ္ဘာလောက", [], "mngglaapkmbhaaleaak", "မင်္ဂလာပါကမ္ဘာလောက", @ascii},
    {"你好，世界", [], "ni-hao-shi-jie", "你好-世界", @ascii},
    {"હેલો, વિશ્વ", [], "helo-vishv", "હેલો-વિશ્વ", @ascii},
    {"Γεια σας, τον κόσμο", [], "geia-sas-ton-kosmo", "γεια-σας-τον-κόσμο", @ascii},
    {"שלום, עולם", [], "shlvm-vlm", "שלום-עולם", @ascii},
    {"नमस्ते दुनिया", [], "nmste-duniyaa", "नमस्ते-दुनिया", @ascii},
    {"こんにちは", [], "konnitiha", "こんにちは", @ascii},
    {"ಹಲೋ, ಪ್ರಪಂಚ", [], "hleuu-prpnc", "ಹಲೋ-ಪ್ರಪಂಚ", @ascii},
    {"សួស្តី\u{200B}ពិភពលោក", [], "suastii-bibhblook", "សួស្តីពិភពលោក", @zero_width},
    {"안녕하세요, 세계", [], "annyeonghaseyo-segye", "안녕하세요-세계", @ascii},
    {"ສະ\u{200B}ບາຍ\u{200B}ດີ\u{200B}ຊາວ\u{200B}ໂລກ", [], "sa-baany-dii-saaw-olk", "ສະບາຍດີຊາວໂລກ",
     @zero_width},
    {"ഹലോ വേൾഡ്", [], "hleeaa-veedd", "ഹലോ-വേൾഡ്", @ascii},
    {"ਸਤਿ ਸ੍ਰੀ ਅਕਾਲ ਦੁਨਿਆ", [], "sti-srii-akaal-duniaa", "ਸਤਿ-ਸ੍ਰੀ-ਅਕਾਲ-ਦੁਨਿਆ", @ascii},
    {"Привет мир", [], "privet-mir", "привет-мир", @ascii},
    {"හෙලෝ වර්ල්ඩ්", [], "heleaa-vrldd", "හෙලෝ-වර්ල්ඩ්", @ascii},
    {"வணக்கம், உலகம்", [], "vnnkkm-ulkm", "வணக்கம்-உலகம்", @ascii},
    {"హలో, ప్రపంచం", [], "hloo-prpncn", "హలో-ప్రపంచం", @ascii},
    {"สวัสดีชาวโลก", [], "swasdiichaawolk", "สวัสดีชาวโลก", @ascii},
    {"Chào thế giới", [], "chao-the-gioi", "chao-the-gioi", nil},
    {"Chào thế giới", [latin: :keep], "chao-the-gioi", "chào-thế-giới",
     "`latin: :keep` leaves Vietnamese letters as typed; slugify writes ASCII"},
    {"העלא וועלט", [], "hl-vvlt", "העלא-וועלט", @ascii}
  ]

  compat_cases(@cases)
end
