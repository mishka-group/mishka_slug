# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.AshTest do
  use ExUnit.Case, async: true

  alias MishkaSlug.Test.Blog.{Page, Post}

  defp create(resource, action \\ :create, input) do
    resource
    |> Ash.Changeset.for_create(action, input)
    |> Ash.create()
  end

  defp change_of(resource, action) do
    [%{change: change}] = Ash.Resource.Info.action(resource, action).changes
    change
  end

  describe "slugify/2" do
    test "is the MishkaSlug.Change tuple with :from first" do
      assert MishkaSlug.Ash.Changes.slugify(:title, into: :slug) ==
               {MishkaSlug.Change, from: :title, into: :slug}
    end

    test "an action that uses it holds a MishkaSlug.Change, as one written as a tuple does" do
      assert {MishkaSlug.Change, opts} = change_of(Page, :create)
      assert {MishkaSlug.Change, ^opts} = change_of(Post, :create)
    end

    test "writes the same slug as the tuple form, for Persian and Latin titles" do
      for input <- [
            %{title: "كتاب React ۱۰"},
            %{title: "قیمت‌گذاری نرم‌افزار"},
            %{title: "Café Crème v1.2", language: "en"},
            %{title: "Привет Hello", language: "en"}
          ] do
        assert {:ok, page} = create(Page, input)
        assert {:ok, post} = create(Post, input)
        assert page.slug == post.slug
      end
    end

    test "Persian keeps its letters and Latin loses its accents" do
      assert {:ok, %{slug: "کتاب-react-۱۰"}} = create(Page, %{title: "كتاب React ۱۰"})
      assert {:ok, %{slug: "cafe-creme"}} = create(Page, %{title: "Café Crème", language: "en"})
    end

    test "an update re-slugs and keeps the change's errors on :from" do
      {:ok, page} = create(Page, %{title: "first"})

      assert {:ok, %{slug: "second-post"}} =
               Ash.update(page, %{title: "Second Post"}, action: :update)

      assert {:error, %Ash.Error.Invalid{errors: [error]}} =
               Ash.update(page, %{title: "p\u{0430}ypal"}, action: :update)

      assert error.field == :title
    end
  end
end
