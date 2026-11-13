# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

import Config

# Only for the test resource: a host app sets this itself. Code points are what MishkaSlug counts.
config :ash, default_string_length_count: :codepoints

config :logger, level: :warning

# Only for the test resource: the preset a host app would keep for the slugs of its public pages.
config :mishka_slug,
  presets: [
    public: [
      from: :title,
      into: :slug,
      language: :language,
      locales: {MishkaSlug.Test.Blog, :site_languages, [["fa", "en"]]},
      keep: ["."]
    ]
  ]
