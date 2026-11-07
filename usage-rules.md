# Rules for Working with Mishka Slug

Mishka Slug makes URL slugs that keep the original script: Persian stays Persian, Hindi stays Hindi, Japanese stays Japanese. Only Latin letters lose their accents (WordPress style). Invisible characters, bidi tricks and words that mix scripts are taken out.

**Important**: Read these rules, and the sub-rules you need, before writing code that makes or reads a slug.

## Setup

```elixir
# mix.exs, in deps/0
{:mishka_slug, "~> 0.0.1"}
```

Ash is optional. `MishkaSlug.Change` is compiled only when the host app has Ash.

## Use it for

- The public address of user content: a post, a page, a category, a tag, a product.
- Titles in any language, including mixed text such as `آموزش React در ۱۰ دقیقه`.

Do not use it for internal identifiers: module names, CSS class names, JS names, file paths, atoms, database column names. Those need ASCII, and this library keeps non-Latin letters on purpose.

## slugify/2 or slugify!/2

```elixir
MishkaSlug.slugify("Café Crème")
#=> {:ok, "cafe-creme"}

MishkaSlug.slugify!("Привет, мир!")
#=> "привет-мир"
```

- `slugify/2` returns `{:ok, slug}` or `{:error, reason}`. Use it for anything a user typed.
- `slugify!/2` returns the slug or raises `ArgumentError`. Use it only when the text is known to have letters or digits (a seed, a constant, text you already checked).
- Invalid options raise `ArgumentError` in both. A non-string `text` raises `FunctionClauseError`.

| Result | When |
|---|---|
| `{:error, :empty}` | nothing is left: `""`, `"😀🚀"`, `"---"` |
| `{:error, :no_allowed_script}` | the text has letters or digits, but none is in a script of `:locales`: `"قیمت"` with `locales: ["en"]` |
| `{:error, :invalid_utf8}` | the binary is not UTF-8 |
| `{:error, :mixed_scripts}` | a word mixes scripts and `mixed_scripts: :reject` is set |
| `{:error, {:unknown_locale, "xx"}}` | a code in `:locales` is not known |

Handle each reason in a `case` or `with`. Never fall back to an empty slug, and never fall back to the raw text:

```elixir
case MishkaSlug.slugify(title, locales: ["fa", "en"]) do
  {:ok, slug} -> slug
  {:error, :empty} -> fallback_slug(id)
  {:error, reason} -> {:error, MishkaSlug.Messages.error(reason)}
end
```

`:empty` is the usual one. `:no_allowed_script` means the text has letters, just not in a script the site allows: tell the user to write with the site's languages (for example Latin letters), not that the text is blank. Ask the user for another title, or build a slug from an id (`"post-" <> id`). `MishkaSlug.Messages.error/1` turns any reason into a translated sentence for a form (see the configuration sub-rules).

## Options

All options are optional. An unknown option, or a value outside the accepted ones, raises `ArgumentError`. The defaults match WordPress.

| Option | Default | Change it when |
|---|---|---|
| `:language` | `nil` | You know the text's language. `"fa"`, `"ur"`, `"ckb"` fold Arabic `ي ى ك` into Persian `ی ک`; `"tr"`, `"az"` lowercase `I` to `ı`; `"de"`, `"da"`, `"ca"`, `"sr"`, `"bs"` spell Latin letters their own way. |
| `:locales` | `[]` | The site has known languages. Only their scripts, and Latin, are kept. `[]` keeps every script. |
| `:mixed_scripts` | `:split` | `:reject` when a word that mixes scripts (a homoglyph attempt) must be refused, not cut. |
| `:zwnj` | `:remove` | `:separator` when the Persian half-space should be a word break. |
| `:digits` | `:keep` | `:ascii` when `۱۴۰۳` and `٢٠٢٥` must become `1403` and `2025`. With `:keep`, `:locales` drops a digit of a script it does not allow, like a letter. |
| `:keep` | `["_"]` | A list of `"."`, `"_"`, `"~"` kept inside a word. It replaces the default. |
| `:latin` | `:ascii` | `:keep` to leave accents as typed (`café`). |
| `:trim_kept` | `false` | `true` to remove kept characters at a word's ends (`__init__` to `init`). The default keeps them like WordPress. |
| `:max_length` | `nil` | The column has a limit. Counted in code points; whole words are kept. |

Verified examples:

```elixir
# Persian: half-space glued, or a break
MishkaSlug.slugify("قیمت‌گذاری نرم‌افزار")
#=> {:ok, "قیمتگذاری-نرمافزار"}
MishkaSlug.slugify("قیمت‌گذاری نرم‌افزار", zwnj: :separator)
#=> {:ok, "قیمت-گذاری-نرم-افزار"}

# Arabic letters folded into Persian
MishkaSlug.slugify("كتاب يك", language: "fa")
#=> {:ok, "کتاب-یک"}

# Arabic is left alone
MishkaSlug.slugify("كتاب جديد", language: "ar")
#=> {:ok, "كتاب-جديد"}

# Digits
MishkaSlug.slugify("سنة ٢٠٢٥ كتاب", digits: :ascii)
#=> {:ok, "سنة-2025-كتاب"}

# A digit of a script outside the locales is dropped, unless :ascii writes it as 0-9 first
MishkaSlug.slugify("سال ۱۴۰۳", locales: ["en"])
#=> {:error, :no_allowed_script}
MishkaSlug.slugify("سال ۱۴۰۳", locales: ["en"], digits: :ascii)
#=> {:ok, "1403"}

# Site languages: Persian and English stay, other scripts are dropped
MishkaSlug.slugify("آموزش React در ۱۰ دقیقه", locales: ["fa", "en"])
#=> {:ok, "آموزش-react-در-۱۰-دقیقه"}
MishkaSlug.slugify("Привет мир Hello", locales: ["en"])
#=> {:ok, "hello"}

# Latin
MishkaSlug.slugify("Café Crème")                    #=> {:ok, "cafe-creme"}
MishkaSlug.slugify("Café Crème", latin: :keep)      #=> {:ok, "café-crème"}
MishkaSlug.slugify("Straße")                        #=> {:ok, "strase"}
MishkaSlug.slugify("Straße Öl", language: "de")     #=> {:ok, "strasse-oel"}
MishkaSlug.slugify("Ærø", language: "da")           #=> {:ok, "aeroe"}
MishkaSlug.slugify("IŞIK Istanbul", language: "tr") #=> {:ok, "isik-istanbul"}

# Other scripts keep their letters
MishkaSlug.slugify("हिन्दी भाषा")                    #=> {:ok, "हिन्दी-भाषा"}
MishkaSlug.slugify("שָׁלוֹם עוֹלָם")                    #=> {:ok, "שלום-עולם"}
MishkaSlug.slugify("東京キャブ乗り場 ラーメン")        #=> {:ok, "東京キャブ乗り場-ラーメン"}
MishkaSlug.slugify("สวัสดีชาวโลก")                   #=> {:ok, "สวัสดีชาวโลก"}
MishkaSlug.slugify("Привет, мир!")                  #=> {:ok, "привет-мир"}

# :keep
MishkaSlug.slugify("snake_case_name")               #=> {:ok, "snake_case_name"}
MishkaSlug.slugify("snake_case_name", keep: [])     #=> {:ok, "snake-case-name"}
MishkaSlug.slugify("v1.2 release", keep: ["."])     #=> {:ok, "v1.2-release"}
MishkaSlug.slugify("v1.2 release")                  #=> {:ok, "v1-2-release"}
MishkaSlug.slugify("snake_case_name", keep: ["."])  #=> {:ok, "snake-case-name"}

# :trim_kept
MishkaSlug.slugify("__init__ my_post_")                    #=> {:ok, "__init__-my_post_"}
MishkaSlug.slugify("__init__ my_post_", trim_kept: true)   #=> {:ok, "init-my_post"}

# :max_length
MishkaSlug.slugify("hello world foo", max_length: 13) #=> {:ok, "hello-world"}

# Always on
MishkaSlug.slugify("pay​pal")                  #=> {:ok, "paypal"}
MishkaSlug.slugify("Q&A don't")                     #=> {:ok, "q-a-dont"}
MishkaSlug.slugify("../etc/passwd")                 #=> {:ok, "etc-passwd"}
MishkaSlug.slugify("pаypal", mixed_scripts: :reject) #=> {:error, :mixed_scripts}
```

`keep` replaces the default, so `keep: ["."]` makes `_` a break again. Write `keep: [".", "_"]` to keep both. Only `"."`, `"_"` and `"~"` are accepted; `"-"` raises.

## Rules

Do:

- Store the slug as Unicode text in a string column. The slug is NFC, so a stored slug equals a pasted one.
- Percent-encode only where the slug leaves your app. In Phoenix, `~p"/posts/#{post.slug}"` does it.
- Pass the site's languages as `locales`, and the post's language as `language`. Keep the same options everywhere the slug is made or compared.
- Keep uniqueness and reserved words in the resource or context that stores the slug. The library does not check them.
- Re-slug an incoming URL parameter with the same options if you want to redirect variants (`slugify/2` is idempotent: a slug it made comes back unchanged).
- Use `max_length` equal to your column limit (the Ash change reads it from the attribute).

Don't:

- Don't use a slug as a module name, atom, CSS class, JS identifier, file path or any internal identifier. Make those ASCII by other means.
- Don't percent-encode before storing, and don't store the percent-encoded form.
- Don't slug again for a lookup with different options than the ones used to store. `latin: :keep` and `latin: :ascii` give different slugs for the same title.
- Don't pass user input as an option key or value without a fixed list. Options raise on unknown keys.
- Don't turn `{:error, :empty}` into `""`. An empty slug breaks routes.
- Don't try to rebuild the title from a slug; it is lossy (case, accents, punctuation).
- Don't add `String.downcase`, `String.normalize` or your own invisible-character clean-up around it. It already does these.

## Sub-rules

- **[Ash](usage-rules/ash.md)**: `MishkaSlug.Change` in a resource, its options and `slug_options/2`.
- **[Configuration](usage-rules/configuration.md)**: the Gettext backend and translating the `mishka_slug` domain.

## Using with usage_rules

```elixir
# mix.exs, in deps/0
{:usage_rules, "~> 1.2", only: :dev}

# mix.exs, in project/0
usage_rules: [
  file: "CLAUDE.md",
  usage_rules: [{:mishka_slug, sub_rules: ["ash", "configuration"]}]
]
```

Then run `mix usage_rules.sync`. Name only the `sub_rules` the project uses.

More: https://hexdocs.pm/mishka_slug
