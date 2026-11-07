# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

if Code.ensure_loaded?(Ash.Resource.Change) do
  defmodule MishkaSlug.Change do
    @options [
               from: [
                 type: :atom,
                 required: true,
                 doc: "The attribute or argument the slug is made from, such as `:title`."
               ],
               into: [
                 type: {:or, [:atom, nil]},
                 default: nil,
                 doc: "The attribute the slug is written to. Defaults to `:from`."
               ],
               skip_if_present?: [
                 type: :boolean,
                 default: false,
                 doc: "Leave the slug alone when the action already sets `:into`."
               ],
               language: [
                 type: {:or, [:atom, :string, nil]},
                 default: nil,
                 doc: """
                 The text's language: an attribute or argument name read from the changeset (such
                 as `:language`), or a fixed code.
                 """
               ],
               locales: [
                 type: {:or, [{:list, :string}, {:tuple, [:atom, :atom, {:list, :any}]}]},
                 default: [],
                 doc: """
                 The site's languages: a list, or `{module, function, args}` called with the
                 changeset first, so a CMS can read them for the changeset's tenant.
                 """
               ]
             ] ++
               Keyword.drop(MishkaSlug.options(), [:language, :locales])

    @schema NimbleOptions.new!(@options)

    @moduledoc """
    An Ash change that writes a slug made by `MishkaSlug.slugify/2`.

        changes do
          change {MishkaSlug.Change, from: :title, into: :slug, language: :language,
                  locales: {MyApp.Sites, :languages, []}, keep: ["."]}
        end

    The change reads `:from` from the action's arguments or changes and does nothing when it is
    not there. A value that is not a string, or a title that gives no slug, is a changeset error on
    `:from`; the slug attribute is never set to `nil` or `""`. When `:max_length` is not given, the
    `max_length` constraint of the `:into` attribute is used.

    ## Options

    #{NimbleOptions.docs(@schema)}
    """

    use Ash.Resource.Change

    alias Ash.Changeset

    @impl true
    def init(opts) do
      case NimbleOptions.validate(opts, @schema) do
        {:ok, opts} -> {:ok, opts}
        {:error, error} -> {:error, Exception.message(error)}
      end
    end

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
          Changeset.add_error(changeset, field: from, message: "is not a string value")

        {:error, reason} ->
          Changeset.add_error(changeset, field: from, message: message(reason))

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

    It resolves `:language` and `:locales` against the changeset and fills `:max_length` from the
    `:into` attribute, so code that makes a slug outside an action (a preview in a form, for
    example) gets the same slug the action will write.
    """
    @spec slug_options(keyword(), Changeset.t()) :: keyword()
    def slug_options(opts, changeset) do
      into = opts[:into] || opts[:from]

      opts
      |> Keyword.drop([:from, :into, :skip_if_present?])
      |> Keyword.put(:language, language(opts[:language], changeset))
      |> Keyword.put(:locales, locales(opts[:locales], changeset))
      |> Keyword.put(:max_length, opts[:max_length] || max_length(changeset.resource, into))
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

    defp message(:empty), do: "has no letters or digits to make a slug from"
    defp message(:mixed_scripts), do: "mixes writing systems inside one word"
    defp message(:invalid_utf8), do: "is not valid UTF-8 text"

    defp message({:unknown_locale, code}),
      do: "uses a site language the slug does not know: #{code}"
  end
end
