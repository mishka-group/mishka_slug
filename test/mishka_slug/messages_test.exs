# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.MessagesTest do
  # Sets the application config, which every test shares.
  use ExUnit.Case, async: false

  alias MishkaSlug.Messages
  alias MishkaSlug.Test.Blog.Post
  alias MishkaSlug.Test.Gettext, as: TestGettext

  doctest MishkaSlug.Messages

  setup do
    previous = Application.fetch_env(:mishka_slug, :gettext_backend)

    on_exit(fn ->
      case previous do
        {:ok, backend} -> Application.put_env(:mishka_slug, :gettext_backend, backend)
        :error -> Application.delete_env(:mishka_slug, :gettext_backend)
      end
    end)
  end

  defp create(input) do
    Post |> Ash.Changeset.for_create(:create, input) |> Ash.create()
  end

  test "the default backend is MishkaSlug.Gettext" do
    assert Messages.gettext_backend() == MishkaSlug.Gettext
  end

  test "the change's error is the Gettext message" do
    assert {:error, %Ash.Error.Invalid{errors: [error]}} = create(%{title: "😀 !!!"})
    assert error.message == Messages.error(:empty)
  end

  test "an unknown locale code is bound into the message" do
    assert Messages.error({:unknown_locale, "zz"}) =~ "zz"
  end

  test "a backend from config translates the change's errors in the process locale" do
    Application.put_env(:mishka_slug, :gettext_backend, TestGettext)
    assert Messages.gettext_backend() == TestGettext

    Gettext.put_locale(TestGettext, "fa")

    assert {:error, %Ash.Error.Invalid{errors: [error]}} = create(%{title: "😀 !!!"})
    assert error.message == "xx: nothing to slug"
    assert Messages.error({:unknown_locale, "zz"}) == "xx: unknown language zz"
    assert Messages.not_a_string() == "xx: not a string"
  end
end
