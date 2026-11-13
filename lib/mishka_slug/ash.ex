# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

if Code.ensure_loaded?(Spark.Dsl.Extension) and Code.ensure_loaded?(Ash.Resource.Change) do
  defmodule MishkaSlug.Ash.Changes do
    @moduledoc """
    The changes `MishkaSlug.Ash` imports into a resource's actions.
    """

    @doc """
    Writes a slug made from `from`: a short form of `{MishkaSlug.Change, [from: from] ++ opts}`.

    `opts` are the options of `MishkaSlug.Change`. The result is that tuple, so code that reads an
    action's changes finds a `MishkaSlug.Change` with its options either way.

        change slugify(:title)
        change slugify(:title, into: :slug, language: :language, locales: ["fa", "en"])
        change slugify(:slug, preset: :public)
    """
    @spec slugify(atom(), keyword()) :: {module(), keyword()}
    def slugify(from, opts \\ []) when is_atom(from) and is_list(opts),
      do: {MishkaSlug.Change, [from: from] ++ opts}
  end

  defmodule MishkaSlug.Ash do
    @moduledoc """
    An Ash extension that brings `MishkaSlug.Ash.Changes.slugify/2` into a resource's actions.

        use Ash.Resource, extensions: [MishkaSlug.Ash]

        actions do
          create :create do
            accept [:title, :language]
            change slugify(:title, into: :slug, language: :language)
          end
        end

    `change slugify(:title, opts)` is the same change as
    `change {MishkaSlug.Change, [from: :title] ++ opts}`, so both forms make the same slug and a
    resource can mix them. The extension adds no DSL section of its own.
    """

    use Spark.Dsl.Extension, imports: [MishkaSlug.Ash.Changes]
  end
end
