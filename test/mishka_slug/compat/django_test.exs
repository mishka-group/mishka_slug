# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Compat.DjangoTest do
  use MishkaSlug.CompatCase

  @moduledoc """
  The `slugify` cases of Django, run against `MishkaSlug`.

  Source: https://github.com/django/django, `tests/utils_tests/test_text.py`
  (`TestUtilsText.test_slugify`), BSD-3-Clause. The strings are Django's; the original column is
  what `django.utils.text.slugify` returns, with `allow_unicode=True` for the Unicode rows.

  | Difference | Why |
  |---|---|
  | `_` | Django keeps underscores in a word; we split there unless `keep: ["_"]`. |
  """

  @underscore "`_` separates words here unless `keep: [\"_\"]` is given"

  @cases [
    {"Hello, World!", [], "hello-world", "hello-world", nil},
    {"spam & eggs", [], "spam-eggs", "spam-eggs", nil},
    {" multiple---dash and  space ", [], "multiple-dash-and-space", "multiple-dash-and-space",
     nil},
    {"\t whitespace-in-value \n", [], "whitespace-in-value", "whitespace-in-value", nil},
    {"underscore_in-value", [], "underscore_in-value", "underscore-in-value", @underscore},
    {"underscore_in-value", [keep: ["_"]], "underscore_in-value", "underscore_in-value", nil},
    {"__strip__underscore-value___", [], "strip__underscore-value", "strip-underscore-value",
     @underscore},
    {"__strip__underscore-value___", [keep: ["_"]], "strip__underscore-value",
     "strip__underscore-value", nil},
    {"--strip-dash-value---", [], "strip-dash-value", "strip-dash-value", nil},
    {"__strip-mixed-value---", [], "strip-mixed-value", "strip-mixed-value", nil},
    {"_ -strip-mixed-value _-", [], "strip-mixed-value", "strip-mixed-value", nil},
    {"spam & ıçüş", [], "spam-ıçüş", "spam-ıçüş", nil},
    {"foo ıç bar", [], "foo-ıç-bar", "foo-ıç-bar", nil},
    {"    foo ıç bar", [], "foo-ıç-bar", "foo-ıç-bar", nil},
    {"你好", [], "你好", "你好", nil},
    {"İstanbul", [], "istanbul", "istanbul", nil},
    {"İstanbul", [language: "tr"], "istanbul", "istanbul", nil},
    {"Istanbul ISPARTA", [language: "tr"], nil, "ıstanbul-ısparta",
     "Django has no language option; with `tr`, `I` lowercases to the Turkish `ı`"}
  ]

  compat_cases(@cases)
end
