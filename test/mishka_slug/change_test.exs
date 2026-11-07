# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.ChangeTest do
  use ExUnit.Case, async: true

  alias MishkaSlug.Test.Blog.Post

  defp create(action \\ :create, input) do
    Post
    |> Ash.Changeset.for_create(action, input)
    |> Ash.create()
  end

  test "writes a Persian slug from the title in the post's language" do
    assert {:ok, post} = create(%{title: "كتاب React ۱۰"})
    assert post.slug == "کتاب-react-۱۰"
  end

  test "drops letters outside the site's languages" do
    assert {:ok, post} = create(%{title: "Привет Hello", language: "en"})
    assert post.slug == "hello"
  end

  test "takes the slug length from the attribute's max_length" do
    assert {:ok, post} = create(%{title: "یک دو سه چهار پنج شش هفت هشت"})
    assert post.slug == "یک-دو-سه-چهار-پنج-شش"
  end

  test "a title without letters or digits is an error on the title, not an empty slug" do
    assert {:error, %Ash.Error.Invalid{errors: [error]}} = create(%{title: "😀 !!!"})
    assert error.field == :title
    assert error.message =~ "slug"
  end

  test "skip_if_present? keeps a slug the action sets" do
    assert {:ok, post} = create(:create_with_slug, %{title: "سلام دنیا", slug: "hello"})
    assert post.slug == "hello"

    assert {:ok, post} = create(:create_with_slug, %{title: "سلام دنیا"})
    assert post.slug == "سلام-دنیا"
  end

  test "an update re-slugs the new title and refuses a mixed-script word" do
    {:ok, post} = create(%{title: "first"})

    assert {:ok, post} =
             post |> Ash.Changeset.for_update(:update, %{title: "Second Post"}) |> Ash.update()

    assert post.slug == "second-post"

    assert {:error, %Ash.Error.Invalid{errors: [error]}} =
             post |> Ash.Changeset.for_update(:update, %{title: "p\u{0430}ypal"}) |> Ash.update()

    assert error.message =~ "writing systems"
  end

  test "slug_options gives the options the action uses, for a slug made outside it" do
    changeset = Ash.Changeset.for_create(Post, :create, %{title: "x", language: "tr"})
    [change] = Ash.Resource.Info.action(Post, :create).changes
    {MishkaSlug.Change, opts} = change.change

    opts = MishkaSlug.Change.slug_options(opts, changeset)

    assert opts[:language] == "tr"
    assert opts[:locales] == ["fa", "en"]
    assert opts[:max_length] == 20
    assert {:ok, "isik"} = MishkaSlug.slugify("IŞIK", opts)
    assert {:ok, "ışık"} = MishkaSlug.slugify("IŞIK", Keyword.put(opts, :latin, :keep))
  end

  test "invalid change options are refused when the change is set up" do
    assert {:error, message} = MishkaSlug.Change.init(from: :title, keep: ["?"])
    assert message =~ "keep"
    assert {:error, message} = MishkaSlug.Change.init(from: :title, latin: :translit)
    assert message =~ "latin"
    assert {:ok, opts} = MishkaSlug.Change.init(from: :title, latin: :keep, keep: [])
    assert opts[:latin] == :keep and opts[:keep] == []
  end
end
