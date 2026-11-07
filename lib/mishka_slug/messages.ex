# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Messages do
  @moduledoc """
  The messages a site admin can see, translated in the locale of the calling process.

  `MishkaSlug.slugify/2` returns atoms such as `{:error, :empty}` and never a text; this module
  turns those reasons into sentences for forms. Every text is looked up in the `mishka_slug`
  domain of `gettext_backend/0`.
  """

  use Gettext, backend: MishkaSlug.Gettext

  @doc """
  Returns the Gettext backend in use: the `:gettext_backend` of the `:mishka_slug` application
  config, or `MishkaSlug.Gettext`.
  """
  @spec gettext_backend() :: module()
  def gettext_backend, do: Application.get_env(:mishka_slug, :gettext_backend, MishkaSlug.Gettext)

  @doc """
  Returns the message for a `MishkaSlug.slugify/2` error reason.

  ## Examples

      iex> MishkaSlug.Messages.error(:empty)
      "has no letters or digits to make a slug from"

      iex> MishkaSlug.Messages.error(:no_allowed_script)
      "uses letters or digits that the site languages do not allow in a slug"
  """
  @spec error(MishkaSlug.reason()) :: String.t()
  def error(:empty),
    do: translate(dgettext_noop("mishka_slug", "has no letters or digits to make a slug from"))

  def error(:no_allowed_script),
    do:
      translate(
        dgettext_noop(
          "mishka_slug",
          "uses letters or digits that the site languages do not allow in a slug"
        )
      )

  def error(:mixed_scripts),
    do: translate(dgettext_noop("mishka_slug", "mixes writing systems inside one word"))

  def error(:invalid_utf8),
    do: translate(dgettext_noop("mishka_slug", "is not valid UTF-8 text"))

  def error({:unknown_locale, code}) do
    translate(
      dgettext_noop("mishka_slug", "uses a site language the slug does not know: %{code}"),
      code: code
    )
  end

  @doc """
  Returns the message for a value that is not a string.

  ## Examples

      iex> MishkaSlug.Messages.not_a_string()
      "is not a string value"
  """
  @spec not_a_string() :: String.t()
  def not_a_string, do: translate(dgettext_noop("mishka_slug", "is not a string value"))

  defp translate(msgid, bindings \\ []),
    do: Gettext.dgettext(gettext_backend(), "mishka_slug", msgid, bindings)
end
