# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Compat.CocurSlugifyTest do
  use MishkaSlug.CompatCase

  @moduledoc """
  The cases of cocur/slugify, run against `MishkaSlug`.

  Source: https://github.com/cocur/slugify, `tests/SlugifyTest.php`, MIT. The strings are the
  project's; the original column is what `Slugify::slugify` returns with the default rules.

  Not ported: the per-language rule sets (`azerbaijani`, `croatian`, `danish`, ...), custom rules,
  the `separator`, `regexp`, `lowercase` and `trim` options. They are ASCII transliteration
  tables; `MishkaSlug` keeps every script but Latin, whose accents it drops like WordPress.

  | Difference | Why |
  |---|---|
  | Letters outside Latin | cocur writes ASCII (`Привет` is `privet`); we keep the script. |
  | German umlauts | cocur writes `ä` as `ae`; we write `a` unless `language: "de"`. |
  | Superscripts and `@` | cocur maps `²` and `@` to `2` and `at`; `²` folds to `2` and `@` separates. |
  | HTML tags | With `strip_tags` cocur removes tags; we do not parse HTML. |
  """

  @ascii "cocur writes ASCII; we keep the letters of the script"
  @latin_keep "`latin: :keep` leaves accented Latin letters as typed; cocur writes ASCII"

  @cases [
    {" a  b ", [], "a-b", "a-b", nil},
    {"Hello", [], "hello", "hello", nil},
    {"Hello World", [], "hello-world", "hello-world", nil},
    {"Hello: World", [], "hello-world", "hello-world", nil},
    {": World", [], "world", "world", nil},
    {"Hello World!", [], "hello-world", "hello-world", nil},
    {"H+e#l1l--o/W§o r.l:d)", [], "h-e-l1l-o-w-o-r-l-d", "h-e-l1l-o-w-o-r-l-d", nil},
    {"Привет мир", [], "privet-mir", "привет-мир", @ascii},
    {"Привіт світ", [], "privit-svit", "привіт-світ", @ascii},
    {"Блоґ їжачка", [], "blog-jizhachka", "блоґ-їжачка", @ascii},
    {"Ä ä Ö ö Ü ü ẞ ß", [], "ae-ae-oe-oe-ue-ue-ss-ss", "a-a-o-o-u-u-s-s",
     "without a language we drop the umlaut and write `ß` as `s`, as WordPress does; cocur spells them out"},
    {"Ä ä Ö ö Ü ü ẞ ß", [language: "de"], "ae-ae-oe-oe-ue-ue-ss-ss", "ae-ae-oe-oe-ue-ue-ss-ss",
     nil},
    {"Á À á à É È é è Ó Ò ó ò Ñ ñ Ú Ù ú ù", [], "a-a-a-a-e-e-e-e-o-o-o-o-n-n-u-u-u-u",
     "a-a-a-a-e-e-e-e-o-o-o-o-n-n-u-u-u-u", nil},
    {"Á À á à É È é è Ó Ò ó ò Ñ ñ Ú Ù ú ù", [latin: :keep], "a-a-a-a-e-e-e-e-o-o-o-o-n-n-u-u-u-u",
     "á-à-á-à-é-è-é-è-ó-ò-ó-ò-ñ-ñ-ú-ù-ú-ù", @latin_keep},
    {"Ύπαρξη Αυτής η Σκουληκομυρμηγκότρυπα", [], "iparxi-autis-i-skoulikomirmigkotripa",
     "ύπαρξη-αυτής-η-σκουληκομυρμηγκότρυπα", @ascii},
    {"Français Œuf où à", [], "francais-oeuf-ou-a", "francais-oeuf-ou-a", nil},
    {"هذه هي اللغة العربية", [], "hthh-hy-llgh-laarby", "هذه-هي-اللغة-العربية", @ascii},
    {"tiếng việt rất khó", [], "tieng-viet-rat-kho", "tieng-viet-rat-kho", nil},
    {"Nguyễn Đăng Khoa", [], "nguyen-dang-khoa", "nguyen-dang-khoa", nil},
    {"Nguyễn Đăng Khoa", [latin: :keep], "nguyen-dang-khoa", "nguyễn-đăng-khoa", @latin_keep},
    {"Nguye\u{0302}\u{0303}n Đăng Khoa", [latin: :keep], nil, "nguyễn-đăng-khoa",
     "the decomposed form is the same word; we write NFC, so it equals the precomposed slug"},
    {"ერთი ორი სამი ოთხი ხუთი", [], "erti-ori-sami-otkhi-khuti", "ერთი-ორი-სამი-ოთხი-ხუთი",
     @ascii},
    {"अ ऒ न द", [], "a-oii-na-tha", "अ-ऒ-न-द", @ascii},
    {"活动日起", [], "huodongriqi", "活动日起", @ascii},
    {"Zażółć żółcią gęślą jaźń", [], "zazolc-zolcia-gesla-jazn", "zazolc-zolcia-gesla-jazn", nil},
    {"°¹²³⁴⁵⁶⁷⁸⁹@₀₁₂₃₄₅₆₇₈₉", [], "0123456789at0123456789", "123456789-0123456789",
     "cocur writes `°` as `0` and `@` as `at`; both separate for us, and the sub- and superscripts fold to digits"},
    {"File Name.tar.gz", [keep: ["."]], "file-name.tar.gz", "file-name.tar.gz", nil},
    {"<p>file</p><!-- foo --> <a href=\"#bar\">name</a>", [], "file-name",
     "p-file-p-foo-a-href-bar-name-a",
     "we do not parse HTML, so tag names and attributes become words"}
  ]

  compat_cases(@cases)
end
