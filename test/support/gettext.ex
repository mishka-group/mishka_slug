# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Test.Gettext do
  @moduledoc false

  use Gettext.Backend, otp_app: :mishka_slug, priv: "test/support/gettext"
end
