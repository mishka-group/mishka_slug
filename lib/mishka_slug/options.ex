# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.Options do
  @moduledoc """
  The options `MishkaSlug.slugify/2` and `MishkaSlug.Change` accept.

  The schema lives here once. `validate/1` checks a keyword list against it, fills the defaults
  and refuses any key it does not know, so a misspelled option is an error and never a silently
  ignored one. See `MishkaSlug.slugify/2` for what each option does.
  """

  use GuardedStruct

  guardedstruct authorized_fields: true do
    field :language, String.t() | nil, default: nil, derives: "validate(optional=[string])"

    field :locales, [String.t()], default: [], derives: "validate(list, each=[string])"

    field :script_resolver, {module(), atom(), list()} | nil,
      default: nil,
      validator: {__MODULE__, :validate_script_resolver}

    field :mixed_scripts, :split | :reject,
      default: :split,
      derives: "validate(enum=Atom[split::reject])"

    field :zwnj, :remove | :separator,
      default: :remove,
      derives: "validate(enum=Atom[remove::separator])"

    field :digits, :keep | :ascii, default: :keep, derives: "validate(enum=Atom[keep::ascii])"

    field :latin, :ascii | :keep, default: :ascii, derives: "validate(enum=Atom[ascii::keep])"

    field :keep, [String.t()], default: ["_"], validator: {__MODULE__, :validate_keep}

    field :trim_kept, boolean(), default: false, derives: "validate(boolean)"

    field :max_length, pos_integer() | nil,
      default: nil,
      derives: "validate(optional=[integer, min_len=1])"
  end

  @keep ~w(. _ ~)

  @doc false
  @spec validate_keep(atom(), term()) :: {:ok, atom(), list()} | {:error, atom(), String.t()}
  def validate_keep(field, chars) when is_list(chars) do
    case Enum.reject(chars, &(&1 in @keep)) do
      [] -> {:ok, field, chars}
      bad -> {:error, field, "accepts only \".\", \"_\" and \"~\", got #{inspect(bad)}"}
    end
  end

  def validate_keep(field, _chars), do: {:error, field, "must be a list of characters"}

  @doc false
  @spec validate_script_resolver(atom(), term()) ::
          {:ok, atom(), term()} | {:error, atom(), String.t()}
  def validate_script_resolver(field, nil), do: {:ok, field, nil}

  def validate_script_resolver(field, {module, function, args} = resolver)
      when is_atom(module) and is_atom(function) and is_list(args),
      do: {:ok, field, resolver}

  def validate_script_resolver(field, _resolver),
    do: {:error, field, "must be {module, function, args}"}

  @doc """
  Validates `opts` and returns them as a keyword list with every default filled in.

  Returns `{:ok, opts}`, or `{:error, message}` that names the options that failed.
  """
  @spec validate(keyword()) :: {:ok, keyword()} | {:error, String.t()}
  def validate(opts) when is_list(opts) do
    case builder(Map.new(opts)) do
      {:ok, struct} -> {:ok, struct |> Map.from_struct() |> Map.to_list()}
      {:error, errors} -> {:error, message(errors)}
    end
  end

  @doc """
  Same as `validate/1`, but returns the options or raises `ArgumentError`.
  """
  @spec validate!(keyword()) :: keyword()
  def validate!(opts) do
    case validate(opts) do
      {:ok, opts} -> opts
      {:error, message} -> raise ArgumentError, message
    end
  end

  @doc false
  @spec message([map()]) :: String.t()
  def message(errors) do
    "invalid options: " <> Enum.map_join(errors, "; ", &"#{&1.field}: #{&1.message}")
  end
end
