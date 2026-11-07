# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Compat.AshSlugTest do
  use ExUnit.Case, async: true

  @moduledoc """
  The behaviours `ash_slug` tests, run against `MishkaSlug.Change`.

  Source: https://github.com/ash-project/ash_slug, `test/ash_slug_test.exs`, MIT. Each test here
  is the matching `ash_slug` test on the `MishkaSlug.Test.Blog.Post` resource.

  | Difference | Why |
  |---|---|
  | `lowercase?: false`, `separator`, `ignore` | `ash_slug` passes them to `Slug`; our change always writes a lowercase slug joined with `-`. |
  | `attribute: :text1` in place | `ash_slug` can slugify an attribute into itself; our `:into` does too, but the test here uses a separate slug attribute. |
  | Language and script | Our change reads the post's language and the site's locales; `ash_slug` has neither. |
  """

  alias MishkaSlug.Test.Blog.Post

  defp create(action \\ :create, input) do
    Post
    |> Ash.Changeset.for_create(action, input)
    |> Ash.create()
  end

  test "the value is slugified into the slug attribute" do
    assert {:ok, post} = create(%{title: "My Test Value!"})
    assert post.slug == "my-test-value"
  end

  test "punctuation in the title becomes hyphens and the title is left as typed" do
    assert {:ok, post} = create(%{title: "Hello, World!"})
    assert post.slug == "hello-world"
    assert Ash.CiString.value(post.title) == "Hello, World!"
  end

  test "a slug the action already sets is kept when skip_if_present? is on" do
    assert {:ok, post} = create(:create_with_slug, %{title: "My Test Value!", slug: "test-one"})
    assert post.slug == "test-one"
  end

  test "a slug the action already sets is replaced when skip_if_present? is off" do
    assert {:ok, post} = create(:create_with_slug, %{title: "My Test Value!"})
    assert post.slug == "my-test-value"
  end

  test "an update makes the slug again from the new value" do
    assert {:ok, post} = create(%{title: "Hello, World!"})
    assert post.slug == "hello-world"

    assert {:ok, post} =
             post
             |> Ash.Changeset.for_update(:update, %{title: "Hello, World! Again"})
             |> Ash.update()

    assert post.slug == "hello-world-again"
  end

  test "an Ash.CiString value is slugified" do
    assert {:ok, post} = create(%{title: Ash.CiString.new("Hello, World!")})
    assert post.slug == "hello-world"
  end

  test "a source that is not a string is an error on that field" do
    assert {:error, %Ash.Error.Invalid{errors: [error]}} =
             create(:create_from_flag, %{flag: false})

    assert error.field == :flag
    assert error.message =~ "is not a string value"
  end
end
