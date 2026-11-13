# Rules for MishkaSlug.Change (Ash)

`MishkaSlug.Change` writes a slug from another attribute in an Ash action. It exists only when Ash is a dependency of the host app. Read the main `usage-rules.md` first for the slug options.

## In a resource

```elixir
attributes do
  attribute :title, :string, allow_nil?: false, public?: true
  attribute :language, :string, default: "fa", public?: true
  attribute :slug, :string, public?: true, constraints: [max_length: 120]
end

actions do
  create :create do
    accept [:title, :language]

    change {MishkaSlug.Change,
            from: :title,
            into: :slug,
            language: :language,
            locales: {MyApp.Sites, :languages, []},
            keep: [".", "_"]}
  end
end
```

With the `MishkaSlug.Ash` extension the same change has a shorter form, and both forms are a `MishkaSlug.Change`:

```elixir
use Ash.Resource, extensions: [MishkaSlug.Ash]

change slugify(:title, into: :slug, language: :language, locales: {MyApp.Sites, :languages, []})
```

An ash_slug change line works as it is: `change slugify(:title, into: :slug, separator: "_", truncate: 30, lowercase?: false)`. `ignore` is not taken; use `:keep`.

## Change options

Every `MishkaSlug.slugify/2` option is accepted as it is. These are the change's own:

| Option | Default | Meaning |
|---|---|---|
| `:from` | required | The attribute or argument the slug is made from. |
| `:into` | the `:from` value | The attribute that gets the slug. |
| `:preset` | `nil` | A name in `config :mishka_slug, :presets`, or `{module, function, args}` returning options. Options beside it win. An unknown name is an `init/1` error. |
| `:unique_suffix` | `false` | `true` saves a slug a unique identity refuses as `slug-2`, `slug-3`, … |
| `:max_suffix` | `10` | The highest suffix `:unique_suffix` tries; then the first error is returned. |
| `:skip_if_present?` | `false` | `true` leaves the slug alone when the action already sets `:into` (a user typed a custom slug). |
| `:language` | `nil` | An attribute or argument name read from the changeset (`:language`), or a fixed code (`"fa"`). |
| `:locales` | `[]` | A list (`["fa", "en"]`), or `{module, function, args}` called as `module.function(changeset, ...args)`, so the site's languages can come from the tenant. |

`init/1` returns an error for an unknown option or an invalid value, so a typo fails at compile time of the resource.

## What the change does

- It reads `:from` from the action's arguments or changes. When it is not there, the change does nothing, so an update that does not touch the title keeps its slug.
- A value that is not a string, or a title that gives no slug (`:empty`, `:no_allowed_script`, `:mixed_scripts` and the rest), is a changeset error on `:from`. The slug attribute is never set to `nil` or `""`.
- Error texts go through Gettext in the process locale (see the configuration sub-rules).
- `:max_length` comes from the `max_length` constraint of the `:into` attribute unless you pass it.
- `ci_string` attributes work as `:from`.
- It supports atomic updates when `:from` is a plain value; an expression is `:not_atomic`.

## slug_options/2

`MishkaSlug.Change.slug_options(opts, changeset)` returns the `slugify/2` options the change would use: language and locales resolved against the changeset, `:max_length` filled from the attribute. Use it for a form preview or any code that slugs outside the action, so the preview equals what is saved.

```elixir
opts = [from: :title, into: :slug, language: :language, locales: ["fa", "en"]]
MishkaSlug.slugify(title, MishkaSlug.Change.slug_options(opts, changeset))
```

## Do and don't

- Do put the change in each action that sets the title (create and update), or the slug will not follow the title.
- Do put a unique identity on the slug attribute (`identities do identity :unique_slug, [:slug] end`, with a tenant attribute if you use multitenancy). The change does not check uniqueness; `unique_suffix: true` only reacts to the identity's error.
- Do set `require_atomic? false` on an update action that uses `unique_suffix: true`; Ash refuses it as atomic. Don't count on the suffix in `bulk_create`/`bulk_update` or inside a transaction you opened yourself.
- Do keep options many resources share in a preset (`config :mishka_slug, presets: [public: [...]]`) and write `change slugify(:title, preset: :public)`.
- Do use `skip_if_present?: true` when users may supply their own slug, and run `slugify/2` on what they supply in a validation.
- Don't change the slug of a published page on every title edit unless you redirect the old one; links break.
- Don't read the language from a different source than the one used to build lookups.
