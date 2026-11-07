# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.ScriptsTest do
  use ExUnit.Case, async: true

  alias MishkaSlug.Scripts

  doctest MishkaSlug.Scripts

  test "every language the CMS offers has scripts, and Latin is always among them" do
    languages =
      ~w(af am ar az be bg bn bs ca ckb cs cy da de el en eo es et eu fa fi fil fr ga gl gu ha he
         hi hr hu hy id is it ja ka kk km kn ko ku ky lo lt lv mk ml mn mr ms mt my nb ne nl no pa
         pl ps pt ro ru sd si sk sl so sq sr sv sw ta te tg th tk tr ug uk ur uz vi yi yo zh zu)

    for language <- languages do
      assert {:ok, scripts} = Scripts.for_locales([language])
      assert :latin in scripts
    end
  end

  test "Japanese includes Han and both kana, Persian is Arabic script" do
    assert {:ok, [:han, :hiragana, :katakana, :latin]} = Scripts.for_locales(["ja"])
    assert {:ok, [:arabic, :latin]} = Scripts.for_locales(["fa"])
    assert {:ok, :any} = Scripts.for_locales([])
  end
end
