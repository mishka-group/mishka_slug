# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Test.Blog do
  @moduledoc "A small Ash domain with a post resource, shaped like Mishka Blog, for the change tests."
  use Ash.Domain, validate_config_inclusion?: false

  resources do
    resource MishkaSlug.Test.Blog.Post
  end

  @doc "The languages of the site a changeset belongs to, as a CMS would read them per tenant."
  @spec site_languages(Ash.Changeset.t(), [String.t()]) :: [String.t()]
  def site_languages(_changeset, languages), do: languages
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
