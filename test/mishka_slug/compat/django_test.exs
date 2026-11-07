# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Compat.DjangoTest do
  use MishkaSlug.CompatCase

  @moduledoc """
  The `slugify` cases of Django, run against `MishkaSlug`.

  Source: https://github.com/django/django, `tests/utils_tests/test_text.py`
  (`TestUtilsText.test_slugify`), BSD-3-Clause. The strings are Django's; the original column is
  what `django.utils.text.slugify` returns, with `allow_unicode=True` for the Unicode rows, which
  run with `latin: :keep` (the mode that keeps accented letters like `allow_unicode` does).

  | Difference | Why |
  |---|---|
  | `_` with `keep: []` | Django keeps underscores in a word, as we do by default; `keep: []` splits there. |
  | Edge `_` | Django strips `_` from both ends; we keep it like WordPress unless `trim_kept: true`. |
  | Turkish `I` | Django has no language option; `tr` lowercases `I` to `ı`. |
  """

  @edge_underscore "Django strips `_` at the edges; we keep it like WordPress unless `trim_kept: true`"
  @underscore "`keep: []` makes `_` a word break; Django keeps it, as our default does"

  @cases [
    {"Hello, World!", [], "hello-world", "hello-world", nil},
    {"spam & eggs", [], "spam-eggs", "spam-eggs", nil},
    {" multiple---dash and  space ", [], "multiple-dash-and-space", "multiple-dash-and-space",
     nil},
    {"\t whitespace-in-value \n", [], "whitespace-in-value", "whitespace-in-value", nil},
    {"underscore_in-value", [], "underscore_in-value", "underscore_in-value", nil},
    {"underscore_in-value", [keep: []], "underscore_in-value", "underscore-in-value",
     @underscore},
    {"__strip__underscore-value___", [trim_kept: true], "strip__underscore-value",
     "strip__underscore-value", nil},
    {"__strip__underscore-value___", [], "strip__underscore-value",
     "__strip__underscore-value___", @edge_underscore},
    {"__strip__underscore-value___", [keep: []], "strip__underscore-value",
     "strip-underscore-value", @underscore},
    {"--strip-dash-value---", [], "strip-dash-value", "strip-dash-value", nil},
    {"__strip-mixed-value---", [trim_kept: true], "strip-mixed-value", "strip-mixed-value", nil},
    {"__strip-mixed-value---", [], "strip-mixed-value", "__strip-mixed-value", @edge_underscore},
    {"_ -strip-mixed-value _-", [trim_kept: true], "strip-mixed-value", "strip-mixed-value", nil},
    {"_ -strip-mixed-value _-", [], "strip-mixed-value", "_-strip-mixed-value-_",
     @edge_underscore},
    {"spam & ıçüş", [latin: :keep], "spam-ıçüş", "spam-ıçüş", nil},
    {"spam & ıçüş", [], "spam-ıçüş", "spam-icus",
     "`latin: :ascii` writes Latin letters without accents, as WordPress does"},
    {"foo ıç bar", [latin: :keep], "foo-ıç-bar", "foo-ıç-bar", nil},
    {"    foo ıç bar", [latin: :keep], "foo-ıç-bar", "foo-ıç-bar", nil},
    {"你好", [], "你好", "你好", nil},
    {"İstanbul", [], "istanbul", "istanbul", nil},
    {"İstanbul", [language: "tr"], "istanbul", "istanbul", nil},
    {"Istanbul ISPARTA", [language: "tr"], nil, "istanbul-isparta",
     "Django has no language option; `tr` lowercases `I` to `ı`, which `latin: :ascii` writes as `i`"},
    {"Istanbul ISPARTA", [language: "tr", latin: :keep], nil, "ıstanbul-ısparta",
     "Django has no language option; with `tr`, `I` lowercases to the Turkish `ı`"}
  ]

  compat_cases(@cases)
end
