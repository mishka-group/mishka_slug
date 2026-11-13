# Changelog for MishkaSlug 0.0.2

- `MishkaSlug.Ash` is an Ash extension that brings `slugify/2` into a resource's actions: `use Ash.Resource, extensions: [MishkaSlug.Ash]`, then `change slugify(:title, into: :slug, language: :language)`. It is the same change as `{MishkaSlug.Change, from: :title, into: :slug, language: :language}`, so code that reads an action's changes, and `MishkaSlug.Change.slug_options/2`, see a `MishkaSlug.Change` either way. It is compiled only when Ash is a dependency
- `MishkaSlug.Change` takes a `:preset`: a name looked up in `config :mishka_slug, :presets`, or `{module, function, args}` that returns the options, so every resource that makes the same kind of slug says it once (`change slugify(:slug, preset: :public)` or `change {MishkaSlug.Change, preset: :public}`). Options given beside it win over the preset's. An unknown name, or a preset that is not a keyword list, is an `init/1` error that names it. `init/1` and `slug_options/2` return the merged options
- `MishkaSlug.Change` takes `unique_suffix: true` (off by default) and `:max_suffix` (default `10`): when the save fails because a unique identity on the slug refused it, the action is saved again as `slug-2`, `slug-3` up to `slug-<max_suffix>`, and returns the first save's error when every one is taken. It runs no query of its own, before or after the save; each try is one more write. A slug that needs a suffix is cut by whole words so the suffix fits `:max_length`. It works for `Ash.create/2` and `Ash.update/2` (an update action needs `require_atomic? false`), not in bulk actions or inside a transaction opened by someone else

# Changelog for MishkaSlug 0.0.1

- Initial version: [mishka.tools/cms](https://mishka.tools/cms)
