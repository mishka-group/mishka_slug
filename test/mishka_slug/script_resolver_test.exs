# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.ScriptResolverTest do
  # Not async: one test sets the application config.
  use ExUnit.Case

  alias MishkaSlug.Scripts

  @resolver {MyApp.LocaleScripts, :scripts, []}

  def only(code, scripts), do: if(code == "xx", do: {:ok, scripts}, else: :error)

  test "without a resolver the built-in table decides" do
    assert {:error, {:unknown_locale, "tt"}} = MishkaSlug.slugify("Сәлам", locales: ["tt"])
    assert {:ok, [:arabic, :latin]} = Scripts.for_locales(["fa"])
  end

  test "a script subtag picks the script in the built-in table" do
    assert {:ok, [:latin]} = Scripts.for_locales(["sr-Latn"])
    assert {:ok, [:cyrillic, :latin]} = Scripts.for_locales(["uz_Cyrl"])
    assert {:ok, [:han, :bopomofo, :latin]} = Scripts.for_locales(["zh-Hant-TW"])
    assert {:ok, [:arabic, :latin]} = Scripts.for_locales(["pa-Arab"])
    assert {:ok, "zdravo"} = MishkaSlug.slugify("Zdravo Здраво", locales: ["sr-Latn"])
  end

  test "the resolver decides each locale, with Latin always allowed" do
    assert {:ok, "сәлам-hello"} =
             MishkaSlug.slugify("Сәлам Hello سلام", locales: ["tt"], script_resolver: @resolver)

    assert {:ok, [:arabic, :latin]} =
             Scripts.for_locales(["xx"], {__MODULE__, :only, [[:arabic]]})
  end

  test "a resolver that does not know a code gives unknown_locale, not the built-in table" do
    assert {:error, {:unknown_locale, "fa"}} =
             MishkaSlug.slugify("سلام", locales: ["tt", "fa"], script_resolver: @resolver)
  end

  test "the config resolver is used, and a per-call resolver wins over it" do
    Application.put_env(:mishka_slug, :script_resolver, @resolver)
    on_exit(fn -> Application.delete_env(:mishka_slug, :script_resolver) end)

    assert {:ok, "сәлам"} = MishkaSlug.slugify("Сәлам", locales: ["tt"])

    assert {:ok, "سلام"} =
             MishkaSlug.slugify("Сәлам سلام",
               locales: ["xx"],
               script_resolver: {__MODULE__, :only, [[:arabic]]}
             )
  end

  test "a resolver that is not {module, function, args} is refused" do
    assert_raise ArgumentError, ~r/script_resolver/, fn ->
      MishkaSlug.slugify("x", script_resolver: &MyApp.LocaleScripts.scripts/1)
    end
  end
end
