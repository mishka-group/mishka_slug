# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MyApp.LocaleScripts do
  @moduledoc false

  # The `:script_resolver` the docs show: Tatar is not in the built-in table.
  def scripts("tt"), do: MishkaSlug.Scripts.from_iso15924("Cyrl")
  def scripts(_code), do: :error
end
