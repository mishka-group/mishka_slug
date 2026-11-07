# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

import Config

# Only for the test resource: a host app sets this itself. Code points are what MishkaSlug counts.
config :ash, default_string_length_count: :codepoints

config :logger, level: :warning
