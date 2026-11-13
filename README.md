<div align="center">

[![Buy Me a Coffee](https://img.shields.io/badge/Buy_Me_a_Coffee-mishkagroup-ffdd00?style=flat-square&logo=buy-me-a-coffee&logoColor=black)](https://www.buymeacoffee.com/mishkagroup)
[![GitHub Sponsors](https://img.shields.io/badge/GitHub_Sponsors-mishka--group-ea4aaa?style=flat-square&logo=github)](https://github.com/sponsors/mishka-group)

# Mishka Slug

**URL slugs that keep the original script, made for [Mishka CMS](https://mishka.tools/cms).**

[Mishka CMS](https://mishka.tools/cms) · [Hire us](https://mishka.tools/hire-us)

</div>

## 📖 What is Mishka Slug?

`mishka_slug` turns a title into a URL slug in its own writing system. Persian stays Persian, Hindi stays Hindi, Japanese stays Japanese: nothing is transliterated. Latin text slugs the way WordPress slugs it, accents removed. Most slug libraries either turn every title into ASCII or keep Unicode with a regex that deletes the vowel signs of Hindi and Thai and turns Arabic and Hebrew marks into hyphens. This one keeps whole words and takes out only what is unsafe or optional.

| Title | Slug |
|---|---|
| `Hello World: Getting Started with Elixir!` | `hello-world-getting-started-with-elixir` |
| `Café Crème brûlée` | `cafe-creme-brulee` |
| `snake_case_name` | `snake_case_name` |
| `قیمت‌گذاری نرم‌افزار` | `قیمتگذاری-نرمافزار` |
| `हिन्दी भाषा नमस्ते` | `हिन्दी-भाषा-नमस्ते` |
| `สวัสดีชาวโลก` | `สวัสดีชาวโลก` |
| `שָׁלוֹם עוֹלָם` | `שלום-עולם` |
| `東京キャブ乗り場 ラーメン` | `東京キャブ乗り場-ラーメン` |
| `Привет, мир!` | `привет-мир` |

## 🚀 Getting started

```elixir
{:mishka_slug, "~> 0.0.2"}
```

```elixir
MishkaSlug.slugify("Café Crème")
#=> {:ok, "cafe-creme"}

MishkaSlug.slugify("Café Crème", latin: :keep)
#=> {:ok, "café-crème"}

MishkaSlug.slugify("Straße", language: "de")
#=> {:ok, "strasse"}

MishkaSlug.slugify("snake_case_name")
#=> {:ok, "snake_case_name"}

MishkaSlug.slugify("snake_case_name", keep: [])
#=> {:ok, "snake-case-name"}

MishkaSlug.slugify("__init__ my_post_")
#=> {:ok, "__init__-my_post_"}

MishkaSlug.slugify("__init__ my_post_", trim_kept: true)
#=> {:ok, "init-my_post"}

MishkaSlug.slugify("آموزش React در ۱۰ دقیقه", locales: ["fa", "en"])
#=> {:ok, "آموزش-react-در-۱۰-دقیقه"}

MishkaSlug.slugify("كتاب يك", language: "fa")
#=> {:ok, "کتاب-یک"}

MishkaSlug.slugify("😀🚀")
#=> {:error, :empty}

MishkaSlug.slugify("قیمت", locales: ["en"])
#=> {:error, :no_allowed_script}

MishkaSlug.slugify!("Привет, мир!")
#=> "привет-мир"
```

`slugify/2` is idempotent: a slug slugged again with the same options is unchanged. A CMS can re-slug an incoming URL parameter and redirect when the result differs, which also folds the variants people paste (uppercase, Arabic `ي` for Persian `ی`, decomposed accents).

English and other Latin text, like WordPress:

- Accents are removed: `Café Crème` gives `cafe-creme`, `Tiếng Việt` gives `tieng-viet`, `Łódź` gives `lodz`, `Straße` gives `strase`.
- The `:language` adds its own spelling: `de` writes `Straße Öl` as `strasse-oel`, `da` writes `Ærø` as `aeroe`, `ca` writes `Col·lecció` as `colleccio`, `sr` and `bs` write `Đorđe` as `djordje`.
- `latin: :keep` leaves the accents as typed: `Café Crème` gives `café-crème`.
- Only Latin changes: Greek, Cyrillic, Arabic and every other script keep their letters and marks.
- `_` stays in a word like WordPress: `snake_case_name` gives `snake_case_name`, and so does `__init__` (`__init__`). `keep: []` makes it a break: `snake-case-name`. `trim_kept: true` removes kept characters at a word's ends: `__init__` gives `init`.
- `.` separates words unless it is in `:keep`: `a_b.c` gives `a_b-c`.
- `&` is dropped (`Q&A` gives `q-a`), an apostrophe inside a word is removed (`don't` gives `dont`), and `1,000` gives `1-000`.
- `:max_length` cuts at whole words: `hello world foo` with `max_length: 13` gives `hello-world`.

## ⚙️ Options

| Option | Default | What it does |
|---|---|---|
| `:language` | `nil` | The text's language. `tr` and `az` lowercase `I` to `ı`, and `fa`, `ur`, `ckb` fold Arabic `ي ى ك` to Persian `ی ک`, and `de`, `da`, `ca`, `sr`, `bs` spell Latin accents their own way. |
| `:locales` | `[]` | The site's languages, such as `["fa", "en"]`. Only their scripts, and Latin, are kept, letters and digits alike: `locales: ["en"]` drops `۱۴۰۳`. `[]` keeps every script. A script subtag picks the script (`sr-Latn` is Latin). |
| `:script_resolver` | `nil` | `{module, function, args}` that gives the scripts of a `:locales` code the built-in table does not know (see below). Also settable app-wide with `config :mishka_slug, :script_resolver, {M, F, A}`; the option wins. |
| `:mixed_scripts` | `:split` | A word that changes script (`pаypal` with a Cyrillic `а`): `:split` cuts it, `:reject` returns `{:error, :mixed_scripts}`. |
| `:zwnj` | `:remove` | The Persian half-space: `:remove` glues the parts, `:separator` makes a word break. |
| `:digits` | `:keep` | `:keep` leaves `۱۴۰۳` as typed, `:ascii` writes `1403`. A digit of a script outside `:locales` is dropped, unless `:ascii` writes it as `0-9` first. |
| `:latin` | `:ascii` | `:ascii` removes Latin accents like WordPress (`café` to `cafe`, `ß` to `s`, or `ss` with `language: "de"`); `:keep` leaves them as typed. Other scripts never change. |
| `:keep` | `["_"]` | `.`, `_` or `~` kept inside a word, such as `snake_case` or `v1.2`. The list replaces the default: `[]` makes `_` a break, `[".", "_"]` keeps both. |
| `:trim_kept` | `false` | `false` keeps `_`, `.` and `~` at a word's ends like WordPress (`__init__`, `my_post_`); `true` removes them (`init`, `my_post`). |
| `:max_length` | `nil` | The longest slug in code points. Whole words while they fit; a long first word is cut between graphemes. |

Options are checked by `MishkaSlug.Options` (a `guarded_struct`). An unknown option or a value outside the accepted ones raises `ArgumentError`.

The built-in table knows about 85 languages. For any other code, or to follow CLDR, plug in a resolver. It is called as `apply(module, function, [code | args])` and returns `{:ok, [script]}` or `:error` (which gives `{:error, {:unknown_locale, code}}`). `MishkaSlug.Scripts.from_iso15924/1` turns a CLDR script code (`"Arab"`, `"Cyrl"`, `"Jpan"`) into the script atoms. With the [`localize`](https://hex.pm/packages/localize) package:

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

MishkaSlug.slugify("Сәлам", locales: ["tt"], script_resolver: {MyApp.LocaleScripts, :scripts, []})
#=> {:ok, "сәлам"}
```

Japanese (Han with kana), Korean (Hangul with Han) and Chinese with Bopomofo count as one script, so their words are never cut.

## 🛡️ Safety

These are always on, not options:

- Invisible characters are removed without leaving a break: zero-width spaces and joiners, bidi controls and isolates (`U+202E`), soft hyphens, byte-order marks, variation selectors, control, private-use and unassigned code points.
- A word never mixes scripts, so a homoglyph cannot pass for a Latin letter inside a word.
- A slug never holds `/ ? # % \ :` or whitespace, and is never `.` or `..`.
- The text is NFKC-normalised first and the slug is NFC, so fullwidth letters, ligatures and Arabic presentation forms become their plain letters.
- Arabic harakat, tatweel and Hebrew points are dropped as optional spelling. Every other mark is kept, because in Indic and Thai scripts the marks spell the word.

Reserved words stay the job of the resource that stores the slug. Uniqueness is too, through a unique identity; `MishkaSlug.Change` can add a `-2`, `-3` suffix when that identity refuses a slug (see below).

## 🧱 In an Ash resource

With Ash in the host, `MishkaSlug.Change` writes the slug in an action:

```elixir
create :create do
  accept [:title, :language]

  change {MishkaSlug.Change,
          from: :title,
          into: :slug,
          language: :language,
          locales: {MyApp.Sites, :languages, []},
          keep: [".", "_"]}
end
```

`language: :language` reads the record's language, and `locales:` takes a list or `{module, function, args}` called with the changeset first, so the site's languages can come from its tenant. A title with no slug is an error on `:title`; the slug is never set to `nil`. Without `:max_length` the `max_length` of the slug attribute is used.

### The `MishkaSlug.Ash` extension

The extension gives the change a shorter form. It is the same `MishkaSlug.Change`, so both forms make the same slug:

```elixir
use Ash.Resource, extensions: [MishkaSlug.Ash]

actions do
  create :create do
    accept [:title, :language]
    change slugify(:title, into: :slug, language: :language, locales: {MyApp.Sites, :languages, []})
  end
end
```

### Presets

Options many resources share can live in one place, by name in the config or from a function:

```elixir
# config/config.exs
config :mishka_slug,
  presets: [
    public: [from: :slug, into: :slug, locales: {MyApp.Sites, :languages, []}],
    internal: [locales: ["en"], keep: [], digits: :ascii]
  ]

change slugify(:title, preset: :public)          # :from is :title, the rest from the preset
change {MishkaSlug.Change, preset: :public}      # the tuple form takes it too
change slugify(:name, preset: :internal, keep: ["_"])   # options beside it win
change slugify(:title, preset: {MyApp.Slugs, :options, []})
```

An unknown preset name is an error when the change is initialised.

### A suffix for a taken slug

With `unique_suffix: true` a slug a unique identity refuses is saved as `slug-2`, then `slug-3`, up to `:max_suffix` (default `10`):

```elixir
identities do
  identity :unique_slug, [:site_id, :slug]
end

actions do
  create :create do
    accept [:title]
    change slugify(:title, into: :slug, unique_suffix: true)
  end

  update :update do
    accept [:title]
    require_atomic? false
    change slugify(:title, into: :slug, unique_suffix: true)
  end
end
```

It is off by default and adds no query when it is on: the action saves as usual, and only a save refused by the slug's unique identity (a Postgres unique index, or an identity's `pre_check_with` on ETS) is tried again with the next suffix, one write per try. When every suffix is taken the first error is returned. It retries through `Ash.Changeset.around_transaction/2`, so an update action needs `require_atomic? false`, bulk actions do not suffix, and an action run inside a transaction someone else opened gets the first error (Postgres aborts that transaction on it).

## 🤖 Usage rules for AI agents

The package ships [usage_rules](https://hexdocs.pm/usage_rules/) files (`usage-rules.md` and `usage-rules/`) so an agent knows the options, the return shapes and the do's and don'ts. Add `{:usage_rules, "~> 1.2", only: :dev}`, set `usage_rules: [file: "CLAUDE.md", usage_rules: [{:mishka_slug, sub_rules: ["ash", "configuration"]}]]` in `project/0`, and run `mix usage_rules.sync`.

## 🗂️ Layout

```
lib/
├── mishka_slug.ex          slugify/2 and slugify!/2, the options and the pipeline
└── mishka_slug/
    ├── options.ex          the options schema, shared by slugify/2 and the change
    ├── scripts.ex          site languages to scripts, and one script per word
    ├── change.ex           the Ash change (compiled when Ash is present)
    └── ash.ex              the Ash extension with slugify/2 (compiled when Ash is present)
usage-rules.md, usage-rules/ rules for AI agents (examples checked by a test)
test/mishka_slug/           real titles per language, safety, options and the Ash change
```

## 🔭 Planned

- [ ] A confusable check for slugs that look like another slug
- [ ] A byte limit beside `:max_length`
- [ ] Replacements such as `&` to `and`

## 🧩 Part of Mishka CMS

Mishka Slug makes the addresses of posts and pages in [Mishka CMS: Open-Source Multi-Site CMS](https://mishka.tools/cms), [Mishka Blog: Open-Source Blog Engine](https://mishka.tools/cms/extensions/blog) and [Mishka Document: Versioned Docs Engine](https://mishka.tools/cms/extensions/documentation).

## 🤝 Contributing

```sh
mix deps.get
mix ci
```

## 💬 Community and support

- Join the [Mishka Discord](https://discord.gg/m4zdCJjDJg) to ask questions and meet the team.
- Report a bug or ask a question in [GitHub issues](https://github.com/mishka-group/mishka_slug/issues).
- Read about new releases on the [Mishka blog](https://mishka.tools/blog).
- For custom work or priority support, [hire the Mishka team](https://mishka.tools/hire-us).

## 💖 Support the project

Mishka CMS and its libraries are free and open source. You can support their development through [GitHub Sponsors](https://github.com/sponsors/mishka-group) or [Buy Me a Coffee](https://www.buymeacoffee.com/mishkagroup).

## 📜 License

Apache License 2.0. See [LICENSE](LICENSE).
