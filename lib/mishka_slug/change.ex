# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

if Code.ensure_loaded?(Ash.Resource.Change) do
  defmodule MishkaSlug.Change.Options do
    @moduledoc false

    use GuardedStruct

    guardedstruct authorized_fields: true do
      field :from, atom(), enforce: true, derives: "validate(atom)"
      field :into, atom() | nil, default: nil, derives: "validate(optional=[atom])"
      field :skip_if_present?, boolean(), default: false, derives: "validate(boolean)"

      field :language, atom() | String.t() | nil,
        default: nil,
        derives: "validate(optional=[either=[atom, string]])"

      field :locales, [String.t()] | {module(), atom(), list()},
        default: [],
        validator: {__MODULE__, :validate_locales}
    end

    @doc false
    def validate_locales(field, locales) when is_list(locales) do
      if Enum.all?(locales, &is_binary/1),
        do: {:ok, field, locales},
        else: {:error, field, "must be a list of strings or {module, function, args}"}
    end

    def validate_locales(field, {module, function, args} = locales)
        when is_atom(module) and is_atom(function) and is_list(args),
        do: {:ok, field, locales}

    def validate_locales(field, _locales),
      do: {:error, field, "must be a list of strings or {module, function, args}"}

    @doc false
    def validate(opts) do
      case builder(Map.new(opts)) do
        {:ok, struct} -> {:ok, struct |> Map.from_struct() |> Map.to_list()}
        {:error, errors} -> {:error, MishkaSlug.Options.message(errors)}
      end
    end
  end
end

if Code.ensure_loaded?(Ash.Resource.Change) do
  defmodule MishkaSlug.Change do
    @moduledoc """
    An Ash change that writes a slug made by `MishkaSlug.slugify/2`.

        changes do
          change {MishkaSlug.Change, from: :title, into: :slug, language: :language,
                  locales: {MyApp.Sites, :languages, []}, keep: [".", "_"]}
        end

    The change reads `:from` from the action's arguments or changes and does nothing when it is
    not there. A value that is not a string, or a title that gives no slug, is a changeset error on
    `:from`; the slug attribute is never set to `nil` or `""`. The error texts go through Gettext
    (see `MishkaSlug.Messages`) in the locale of the calling process. When `:max_length` is not given, the
    `max_length` constraint of the `:into` attribute is used.

    ## Options

    The options of `MishkaSlug.slugify/2` (see `MishkaSlug.Options`) are accepted as they are,
    except `:language` and `:locales`, which take more here. Unknown options and invalid values
    make `init/1` return an error. These are the change's own:

      * `:from` - `atom()`, required. The attribute or argument the slug is made from, such as
        `:title`.

      * `:into` - `atom() | nil`, default `nil`. The attribute the slug is written to. Defaults
        to `:from`.

      * `:skip_if_present?` - `boolean()`, default `false`. Leave the slug alone when the action
        already sets `:into`.

      * `:language` - `atom() | String.t() | nil`, default `nil`. The text's language: an
        attribute or argument name read from the changeset (such as `:language`), or a fixed
        code.

      * `:locales` - `[String.t()] | {module, function, args}`, default `[]`. The site's
        languages: a list, or `{module, function, args}` called with the changeset first, so a
        CMS can read them for the changeset's tenant.

      * `:preset` - `atom() | {module, function, args}`, default `nil`. A named set of options
        the app keeps in one place, so every resource that makes the same kind of slug says it once:

            # config/config.exs
            config :mishka_slug,
              presets: [
                public: [from: :slug, into: :slug, locales: {MyApp.Sites, :languages, []}]
              ]

            change {MishkaSlug.Change, preset: :public}
            change {MishkaSlug.Change, preset: :public, from: :title}

        A name is looked up in `config :mishka_slug, :presets`; `{module, function, args}` is
        called and returns the options. Options given next to `:preset` win over the preset's.
        An unknown name, or a preset that is not a keyword list, makes `init/1` return an error.
    """

    use Ash.Resource.Change

    alias Ash.Changeset
    alias MishkaSlug.Change.Options, as: ChangeOptions
    alias MishkaSlug.Messages
    alias MishkaSlug.Options

    @own_keys [:from, :into, :skip_if_present?, :language, :locales]

    @impl true
    def init(opts) when is_list(opts) do
      with {:ok, opts} <- with_preset(opts),
           {:ok, own} <- ChangeOptions.validate(Keyword.take(opts, @own_keys)),
           {:ok, slug} <- Options.validate(Keyword.drop(opts, @own_keys)) do
        {:ok, Keyword.merge(slug, own)}
      end
    end

    def init(_opts), do: {:error, "invalid options: expected a keyword list"}

    @impl true
    def change(changeset, opts, _context) do
      from = opts[:from]
      into = opts[:into] || from

      with false <- opts[:skip_if_present?] and Changeset.changing_attribute?(changeset, into),
           {:ok, value} when is_binary(value) <- fetch(changeset, from),
           {:ok, slug} <- MishkaSlug.slugify(value, slug_options(opts, changeset)) do
        Changeset.force_change_attribute(changeset, into, slug)
      else
        {:ok, _value} ->
          Changeset.add_error(changeset, field: from, message: Messages.not_a_string())

        {:error, reason} ->
          Changeset.add_error(changeset, field: from, message: Messages.error(reason))

        _skip ->
          changeset
      end
    end

    @impl true
    def atomic(changeset, opts, context) do
      case Keyword.fetch(changeset.atomics, opts[:from]) do
        {:ok, value} when is_binary(value) or is_struct(value, Ash.CiString) ->
          {:ok, change(changeset, opts, context)}

        {:ok, _expression} ->
          {:not_atomic, "a slug cannot be made from an expression"}

        :error ->
          {:ok, change(changeset, opts, context)}
      end
    end

    @doc """
    Returns the `MishkaSlug.slugify/2` options this change uses for a changeset.

    It merges in the options of a `:preset`, resolves `:language` and `:locales` against the changeset and fills `:max_length` from the
    `:into` attribute, so code that makes a slug outside an action (a preview in a form, for
    example) gets the same slug the action will write.
    """
    @spec slug_options(keyword(), Changeset.t()) :: keyword()
    def slug_options(opts, changeset) do
      opts = with_preset!(opts)
      into = opts[:into] || opts[:from]

      opts
      |> Keyword.drop([:from, :into, :skip_if_present?])
      |> Keyword.put(:language, language(opts[:language], changeset))
      |> Keyword.put(:locales, locales(opts[:locales], changeset))
      |> Keyword.put(:max_length, opts[:max_length] || max_length(changeset.resource, into))
    end

    defp with_preset!(opts) do
      case with_preset(opts) do
        {:ok, opts} -> opts
        {:error, message} -> raise ArgumentError, message
      end
    end

    defp with_preset(opts) do
      case Keyword.pop(opts, :preset) do
        {nil, opts} ->
          {:ok, opts}

        {preset, opts} ->
          with {:ok, preset} <- preset(preset), do: {:ok, Keyword.merge(preset, opts)}
      end
    end

    defp preset({module, function, args} = mfa)
         when is_atom(module) and is_atom(function) and is_list(args),
         do: keyword(apply(module, function, args), inspect(mfa))

    defp preset(name) when is_atom(name) do
      case Keyword.fetch(Application.get_env(:mishka_slug, :presets, []), name) do
        {:ok, preset} ->
          keyword(preset, "#{inspect(name)} in config :mishka_slug, :presets")

        :error ->
          {:error,
           "invalid options: preset: no preset #{inspect(name)} in config :mishka_slug, :presets"}
      end
    end

    defp preset(_preset),
      do: {:error, "invalid options: preset: must be a name or {module, function, args}"}

    defp keyword(preset, source) do
      if Keyword.keyword?(preset),
        do: {:ok, preset},
        else: {:error, "invalid options: preset: #{source} must be a keyword list"}
    end

    defp fetch(changeset, from) do
      changeset
      |> Changeset.fetch_argument_or_change(from)
      |> then(fn
        :error -> Keyword.fetch(changeset.atomics, from)
        found -> found
      end)
      |> case do
        {:ok, %Ash.CiString{} = value} -> {:ok, Ash.CiString.value(value)}
        {:ok, nil} -> :error
        result -> result
      end
    end

    defp language(nil, _changeset), do: nil
    defp language(code, _changeset) when is_binary(code), do: code

    defp language(field, changeset) do
      case Changeset.get_argument_or_attribute(changeset, field) do
        nil -> nil
        value -> to_string(value)
      end
    end

    defp locales(locales, _changeset) when is_list(locales), do: locales

    defp locales({module, function, args}, changeset),
      do: apply(module, function, [changeset | args])

    defp max_length(resource, into) do
      case Ash.Resource.Info.attribute(resource, into) do
        %{constraints: constraints} -> constraints[:max_length]
        nil -> nil
      end
    end
  end
end
