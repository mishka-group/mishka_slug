# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Gettext do
  @moduledoc """
  Default Gettext backend for MishkaSlug.

  It holds the messages a site admin can see, such as the errors `MishkaSlug.Change` puts on a
  form field, in the `mishka_slug` domain.

  ## Using your own Gettext backend

  Configure your application to use a custom Gettext backend:

      config :mishka_slug, :gettext_backend, MyAppWeb.Gettext

  Then copy `priv/gettext/mishka_slug.pot` and the `mishka_slug.po` files from MishkaSlug into
  your project's `priv/gettext` directory and translate them there.
  """

  use Gettext.Backend, otp_app: :mishka_slug, priv: "priv/gettext"
end
