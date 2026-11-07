# Rules for Mishka Slug configuration

Mishka Slug has one application setting: the Gettext backend. Everything else is passed as options to `MishkaSlug.slugify/2` or `MishkaSlug.Change`.

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

## Do and don't

- Do set the backend in `config/config.exs` (or `runtime.exs`); `MishkaSlug.Messages.gettext_backend/0` reads it at run time.
- Do keep the domain name `mishka_slug`; it is fixed.
- Don't show `inspect(reason)` to users; use `MishkaSlug.Messages.error/1`.
- Don't put slug options in application config. There is none: pass them in code, or in the change, so every call site shows what it uses.
