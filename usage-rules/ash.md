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

## Change options

Every `MishkaSlug.slugify/2` option is accepted as it is. These are the change's own:

| Option | Default | Meaning |
|---|---|---|
| `:from` | required | The attribute or argument the slug is made from. |
| `:into` | the `:from` value | The attribute that gets the slug. |
| `:skip_if_present?` | `false` | `true` leaves the slug alone when the action already sets `:into` (a user typed a custom slug). |
| `:language` | `nil` | An attribute or argument name read from the changeset (`:language`), or a fixed code (`"fa"`). |
| `:locales` | `[]` | A list (`["fa", "en"]`), or `{module, function, args}` called as `module.function(changeset, ...args)`, so the site's languages can come from the tenant. |

`init/1` returns an error for an unknown option or an invalid value, so a typo fails at compile time of the resource.

## What the change does

- It reads `:from` from the action's arguments or changes. When it is not there, the change does nothing, so an update that does not touch the title keeps its slug.
- A value that is not a string, or a title that gives no slug (`:empty`, `:mixed_scripts` and the rest), is a changeset error on `:from`. The slug attribute is never set to `nil` or `""`.
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
- Do put a unique identity on the slug attribute (`identities do identity :unique_slug, [:slug] end`, with a tenant attribute if you use multitenancy). The change does not check uniqueness.
- Do use `skip_if_present?: true` when users may supply their own slug, and run `slugify/2` on what they supply in a validation.
- Don't change the slug of a published page on every title edit unless you redirect the old one; links break.
- Don't read the language from a different source than the one used to build lookups.
