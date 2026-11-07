# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Compat.LaravelTest do
  use MishkaSlug.CompatCase

  @moduledoc """
  The `Str::slug` cases of Laravel, run against `MishkaSlug`.

  Source: https://github.com/laravel/framework, `tests/Support/SupportStrTest.php`
  (`testSlug`), MIT. The strings are Laravel's; the original column is what `Str::slug` returns
  with the language and dictionary given in the test.

  Not ported: the separator argument (`'_'`, `''`) and the `dictionary` argument. `MishkaSlug`
  always joins with `-` and has no replacement table.

  | Difference | Why |
  |---|---|
  | `@` | Laravel's default dictionary writes `@` as `at`; we treat it as a separator. |
  | `$` and other symbols | Laravel replaces them from the dictionary you pass; we have none. |
  | Arabic with `en` | Laravel transliterates Arabic when the language is `en`; we keep it. |
  """

  @dictionary "Laravel replaces the symbol through its dictionary; we have no dictionary and break the word"

  @cases [
    {"hello world", [], "hello-world", "hello-world", nil},
    {"hello-world", [], "hello-world", "hello-world", nil},
    {"hello_world", [], "hello-world", "hello-world", nil},
    {"user@host", [], "user-at-host", "user-host",
     "Laravel writes `@` as the word `at`; we treat `@` as a separator"},
    {"سلام دنیا", [], "سلام-دنیا", "سلام-دنیا", nil},
    {"some text", [], "some-text", "some-text", nil},
    {"", [], :empty, :empty, nil},
    {"بسم الله", [], "bsm-allah", "بسم-الله",
     "Laravel transliterates Arabic when the language is `en`; we keep the script"},
    {"500$ bill", [], "500-dollar-bill", "500-bill", @dictionary},
    {"500--$----bill", [], "500-dollar-bill", "500-bill", @dictionary},
    {"500-$-bill", [], "500-dollar-bill", "500-bill", @dictionary},
    {"500$--bill", [], "500-dollar-bill", "500-bill", @dictionary},
    {"500-$--bill", [], "500-dollar-bill", "500-bill", @dictionary},
    {"أحمد@المدرسة", [], "أحمد-في-المدرسة", "أحمد-المدرسة", @dictionary}
  ]

  compat_cases(@cases)
end
