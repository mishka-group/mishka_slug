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

  describe ":preset" do
    test "a preset from config makes the slug the full options make" do
      for action <- [:create_preset, :create_preset_tuple] do
        assert {:ok, %{slug: "کتاب-react-۱۰"}} = create(Page, action, %{title: "كتاب React ۱۰"})

        assert {:ok, %{slug: "v1.2-hello"}} =
                 create(Page, action, %{title: "v1.2 Привет Hello", language: "en"})
      end
    end

    test "a preset from {module, function, args} is called for its options" do
      assert {:ok, %{slug: "v1.2-سلام"}} = create(Page, :create_preset_mfa, %{title: "v1.2 سلام"})
    end

    test "options next to the preset win over the preset's" do
      assert {:ok, %{slug: "v1-2-café"}} =
               create(Page, :create_preset_override, %{title: "v1.2 Café", language: "en"})
    end

    test "an unknown preset, or one that is not options, is an init error that names it" do
      assert {:error, message} = MishkaSlug.Change.init(from: :title, preset: :missing)
      assert message =~ ":missing"

      assert {:error, message} =
               MishkaSlug.Change.init(from: :title, preset: {Enum, :to_list, [1..2]})

      assert message =~ "keyword list"

      assert {:error, _message} = MishkaSlug.Change.init(from: :title, preset: "public")
    end

    test "a preset's options are checked like the change's own" do
      assert {:error, message} =
               MishkaSlug.Change.init(
                 from: :title,
                 preset: {MishkaSlug.Test.Blog, :preset, [[keep: ["/"]]]}
               )

      assert message =~ "keep"
    end

    test "init/1 and slug_options/2 return the merged options, without :preset" do
      {MishkaSlug.Change, opts} = change_of(Page, :create_preset_override)
      changeset = Ash.Changeset.for_create(Page, :create_preset_override, %{language: "en"})

      assert {:ok, ready} = MishkaSlug.Change.init(opts)
      refute Keyword.has_key?(ready, :preset)
      assert ready[:from] == :title
      assert ready[:into] == :slug
      assert ready[:keep] == []

      for opts <- [opts, ready] do
        slug_options = MishkaSlug.Change.slug_options(opts, changeset)
        refute Keyword.has_key?(slug_options, :preset)
        assert slug_options[:language] == "en"
        assert slug_options[:locales] == ["fa", "en"]
        assert slug_options[:keep] == []
        assert slug_options[:latin] == :keep
        assert slug_options[:max_length] == 9
      end
    end
  end
end
