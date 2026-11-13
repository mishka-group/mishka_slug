# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Test.Blog do
  @moduledoc "A small Ash domain with a post resource, shaped like Mishka Blog, for the change tests."
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource MishkaSlug.Test.Blog.Post
    resource MishkaSlug.Test.Blog.Page
    resource MishkaSlug.Test.Blog.Tag
    resource MishkaSlug.Test.Blog.Label
  end

  @doc "The languages of the site a changeset belongs to, as a CMS would read them per tenant."
  @spec site_languages(Ash.Changeset.t(), [String.t()]) :: [String.t()]
  def site_languages(_changeset, languages), do: languages

  @doc """
  Refuses a label whose slug is taken with the error AshPostgres makes of a unique index violation
  (`AshPostgres.DataLayer` turns it into an `InvalidAttribute` on the identity's first key, with
  `constraint_type: :unique`), for a data layer that has no unique index.
  """
  @spec unique_index(Ash.Changeset.t(), Ash.Resource.Change.Context.t()) :: Ash.Changeset.t()
  def unique_index(changeset, _context) do
    slug = Ash.Changeset.get_attribute(changeset, :slug)

    case Ash.read!(MishkaSlug.Test.Blog.Label) |> Enum.any?(&(&1.slug == slug)) do
      false ->
        changeset

      true ->
        Ash.Changeset.add_error(
          changeset,
          Ash.Error.Changes.InvalidAttribute.exception(
            field: :slug,
            message: "has already been taken",
            private_vars: [constraint: "labels_unique_slug_index", constraint_type: :unique]
          )
        )
    end
  end

  @doc "A preset as a host would build it in code: Persian and English, `.` kept."
  @spec preset(keyword()) :: keyword()
  def preset(extra \\ []),
    do: [locales: ["fa", "en"], keep: ["."]] ++ extra
end

defmodule MishkaSlug.Test.Blog.Post do
  @moduledoc "A blog post whose slug is made from its title in the post's language."
  use Ash.Resource, domain: MishkaSlug.Test.Blog, data_layer: Ash.DataLayer.Ets

  ets do
    private? true
  end

  attributes do
    uuid_primary_key :id
    attribute :title, :ci_string, public?: true
    attribute :language, :string, public?: true, default: "fa"
    attribute :slug, :string, public?: true, constraints: [max_length: 20]
    attribute :flag, :boolean, public?: true
  end

  actions do
    defaults [:read]

    create :create do
      accept [:title, :language]

      change {MishkaSlug.Change,
              from: :title,
              into: :slug,
              language: :language,
              locales: {MishkaSlug.Test.Blog, :site_languages, [["fa", "en"]]},
              keep: ["."]}
    end

    create :create_with_slug do
      accept [:title, :slug]
      change {MishkaSlug.Change, from: :title, into: :slug, skip_if_present?: true}
    end

    create :create_from_flag do
      accept [:flag]
      change {MishkaSlug.Change, from: :flag, into: :slug}
    end

    update :update do
      accept [:title]
      change {MishkaSlug.Change, from: :title, into: :slug, mixed_scripts: :reject}
    end
  end
end

defmodule MishkaSlug.Test.Blog.Page do
  @moduledoc "A page whose actions write their slug through the `MishkaSlug.Ash` extension."
  use Ash.Resource,
    domain: MishkaSlug.Test.Blog,
    data_layer: Ash.DataLayer.Ets,
    extensions: [MishkaSlug.Ash]

  ets do
    private? true
  end

  attributes do
    uuid_primary_key :id
    attribute :title, :ci_string, public?: true
    attribute :language, :string, public?: true, default: "fa"
    attribute :slug, :string, public?: true, constraints: [max_length: 20]
  end

  actions do
    defaults [:read]

    create :create do
      accept [:title, :language]

      change slugify(:title,
               into: :slug,
               language: :language,
               locales: {MishkaSlug.Test.Blog, :site_languages, [["fa", "en"]]},
               keep: ["."]
             )
    end

    update :update do
      accept [:title]
      change slugify(:title, into: :slug, mixed_scripts: :reject)
    end

    update :update_unique do
      accept [:title]
      change slugify(:title, into: :slug, unique_suffix: true)
    end

    create :create_preset do
      accept [:title, :language]
      change slugify(:title, preset: :public)
    end

    create :create_preset_tuple do
      accept [:title, :language]
      change {MishkaSlug.Change, preset: :public}
    end

    create :create_preset_mfa do
      accept [:title, :language]
      change slugify(:title, into: :slug, preset: {MishkaSlug.Test.Blog, :preset, []})
    end

    create :create_preset_override do
      accept [:title, :language]
      change slugify(:title, preset: :public, keep: [], latin: :keep, max_length: 9)
    end
  end
end

defmodule MishkaSlug.Test.Blog.Tag do
  @moduledoc "A tag whose slug is unique, checked by an identity, for `:unique_suffix`."
  use Ash.Resource,
    domain: MishkaSlug.Test.Blog,
    data_layer: Ash.DataLayer.Ets,
    extensions: [MishkaSlug.Ash]

  ets do
    private? true
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, public?: true
    attribute :slug, :string, public?: true, constraints: [max_length: 12]
  end

  identities do
    identity :unique_slug, [:slug], pre_check?: true
  end

  actions do
    defaults [:read]

    create :create do
      accept [:name]
      change slugify(:name, into: :slug, unique_suffix: true)
    end

    create :create_strict do
      accept [:name]
      change slugify(:name, into: :slug)
    end

    create :create_underscore do
      accept [:name]
      change slugify(:name, into: :slug, separator: "_", unique_suffix: true)
    end

    create :create_short do
      accept [:name]
      change {MishkaSlug.Change, from: :name, into: :slug, unique_suffix: true, max_suffix: 3}
    end

    create :create_with_slug do
      accept [:name, :slug]
      change slugify(:name, into: :slug, skip_if_present?: true, unique_suffix: true)
    end

    update :update do
      accept [:name]
      require_atomic? false
      change slugify(:name, into: :slug, unique_suffix: true)
    end
  end
end

defmodule MishkaSlug.Test.Blog.Label do
  @moduledoc """
  A label whose unique slug is refused the way a Postgres unique index refuses it.

  Its identity has no `pre_check_with`, as on Postgres, so the refusal is the before-action
  `MishkaSlug.Test.Blog.unique_index/2` gives. `testing_identities/0` tells Ash's
  `RequirePreCheckWith` verifier that ETS not checking the identity is meant.
  """
  use Ash.Resource,
    domain: MishkaSlug.Test.Blog,
    data_layer: Ash.DataLayer.Ets,
    extensions: [MishkaSlug.Ash]

  @doc false
  def testing_identities, do: true

  ets do
    private? true
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, public?: true
    attribute :slug, :string, public?: true
  end

  identities do
    identity :unique_slug, [:slug]
  end

  actions do
    defaults [:read]

    create :create do
      accept [:name]
      change slugify(:name, into: :slug, unique_suffix: true)
      change before_action(&MishkaSlug.Test.Blog.unique_index/2)
    end
  end
end
