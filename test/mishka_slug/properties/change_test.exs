# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Properties.ChangeTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  @moduledoc """
  The Ash change writes the slug `MishkaSlug.slugify/2` makes, for any title.
  """

  alias MishkaSlug.SlugGen
  alias MishkaSlug.Test.Blog.Post

  @languages ["fa", "en", "tr", "ru", "ar", "xx", nil]

  defp create(title, language) do
    input = if language, do: %{title: title, language: language}, else: %{title: title}

    Post
    |> Ash.Changeset.for_create(:create, input)
    |> Ash.create()
  end

  defp title do
    one_of([SlugGen.text(), SlugGen.english_title()])
  end

  property "the change sets the slug slugify/2 returns, or an error on the title when there is none" do
    check all(title <- title(), language <- member_of(@languages), max_runs: 1_000) do
      expected =
        MishkaSlug.slugify(title,
          language: language || "fa",
          locales: ["fa", "en"],
          keep: ["."],
          max_length: 20
        )

      case {create(title, language), expected} do
        {{:ok, post}, {:ok, slug}} ->
          assert post.slug == slug

        {{:error, %Ash.Error.Invalid{errors: errors}}, {:error, _reason}} ->
          assert Enum.all?(errors, &(&1.field == :title))

        {{:ok, post}, {:error, _reason}} ->
          assert post.slug == nil and String.trim(title) == ""
      end
    end
  end

  property "the written slug is never longer than the attribute allows" do
    check all(title <- title(), max_runs: 1_000) do
      with {:ok, %{slug: slug}} when is_binary(slug) <- create(title, "fa") do
        assert String.length(slug) <= 20
        assert String.valid?(slug) and SlugGen.nfc(slug) == slug
      end
    end
  end

  property "the written slug is stable when slugged again with the change's options" do
    check all(title <- title(), max_runs: 1_000) do
      with {:ok, %{slug: slug}} when is_binary(slug) <- create(title, "fa") do
        opts = [language: "fa", locales: ["fa", "en"], keep: ["."], max_length: 20]
        assert MishkaSlug.slugify(slug, opts) == {:ok, slug}
      end
    end
  end
end
