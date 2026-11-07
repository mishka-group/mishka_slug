# Rules for Mishka Slug configuration

Mishka Slug has two application settings: the Gettext backend and the script resolver. Everything else is passed as options to `MishkaSlug.slugify/2` or `MishkaSlug.Change`.

## Gettext backend

`slugify/2` returns atoms such as `{:error, :empty}`, never text. Only `MishkaSlug.Messages` (and so `MishkaSlug.Change`'s changeset errors) produces sentences, in the `mishka_slug` Gettext domain.

By default the texts come from the library's own backend, `MishkaSlug.Gettext`, which ships English. To translate them, use your own backend:

```elixir
# config/config.exs
config :mishka_slug, :gettext_backend, MyAppWeb.Gettext
```

Then copy `priv/gettext/mishka_slug.pot` (from the `mishka_slug` dependency) into your project's `priv/gettext`, make a `LC_MESSAGES/mishka_slug.po` per locale, and translate the `msgstr` entries:

```
priv/gettext/fa/LC_MESSAGES/mishka_slug.po
```

The messages are:

- `has no letters or digits to make a slug from` (`:empty`)
- `uses letters or digits that the site languages do not allow in a slug` (`:no_allowed_script`)
- `mixes writing systems inside one word` (`:mixed_scripts`)
- `is not valid UTF-8 text` (`:invalid_utf8`)
- `uses a site language the slug does not know: %{code}` (`{:unknown_locale, code}`)
- `is not a string value` (the value is not a binary)

Keep the `%{code}` placeholder in the translation. The text is looked up in the locale of the calling process (`Gettext.put_locale/2`).

```elixir
MishkaSlug.Messages.error(:empty)
#=> "has no letters or digits to make a slug from"
```

## Script resolver

`:locales` codes become scripts through a built-in table of about 85 languages; a script subtag picks the script (`sr-Latn` is Latin, `zh-Hant` Han). A code it does not know is `{:error, {:unknown_locale, code}}`. A host that already resolves languages, or needs more of them, plugs in its own resolver for every call:

```elixir
# config/config.exs
config :mishka_slug, :script_resolver, {MyApp.LocaleScripts, :scripts, []}
```

It is called as `apply(module, function, [code | args])` and returns `{:ok, [script]}` or `:error`. The scripts are the atoms of `MishkaSlug.Scripts` (`:latin`, `:arabic`, `:cyrillic`, `:han`, ...), and `MishkaSlug.Scripts.from_iso15924/1` turns a CLDR script code (`"Arab"`, `:Cyrl`, `"Jpan"`) into them. `:error` gives `{:error, {:unknown_locale, code}}`; the built-in table is not asked. Latin is always allowed. With the `localize` package (CLDR likely subtags):

```elixir
defmodule MyApp.LocaleScripts do
  def scripts(code) do
    with {:ok, tag} <- Localize.LanguageTag.parse(code),
         {:ok, tag} <- Localize.LanguageTag.add_likely_subtags(tag) do
      MishkaSlug.Scripts.from_iso15924(tag.script)
    else
      _ -> :error
    end
  end
end
```

The `:script_resolver` option of `MishkaSlug.slugify/2` (and of `MishkaSlug.Change`) wins over the config for that call.

## Do and don't

- Do set the backend in `config/config.exs` (or `runtime.exs`); `MishkaSlug.Messages.gettext_backend/0` reads it at run time.
- Do keep the domain name `mishka_slug`; it is fixed.
- Don't show `inspect(reason)` to users; use `MishkaSlug.Messages.error/1`.
- Don't put other slug options in application config. Only the script resolver is read from there: pass the rest in code, or in the change, so every call site shows what it uses.
