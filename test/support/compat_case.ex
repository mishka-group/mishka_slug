# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.CompatCase do
  @moduledoc """
  Runs the cases ported from other slug libraries.

  Each case is `{input, options, original, ours, why}`:

  - `input` and `options` are what `MishkaSlug.slugify/2` is called with.
  - `original` is what the other library returns for the same input (`:empty` when it returns
    nothing), or `nil` when it has no comparable output.
  - `ours` is what `MishkaSlug` returns: a slug, or the `:empty` / `:mixed_scripts` error reason.
  - `why` is `nil` when both agree, and one short sentence saying why we differ otherwise.

  Every case checks our result, that slugging our slug again gives the same slug, and that `why`
  is set exactly when `original` and `ours` differ. A case ending in `:known_bug` is excluded from
  the run: `ours` is the result it should have, not what the code returns today.
  """

  import ExUnit.Assertions

  @typedoc "The reason a case differs from the original library, or `nil` when it does not."
  @type why :: String.t() | nil

  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case, async: true
      import MishkaSlug.CompatCase, only: [compat_cases: 1]
    end
  end

  @doc "Defines one test per case in `cases` inside the calling test module."
  defmacro compat_cases(cases) do
    quote bind_quoted: [cases: cases], unquote: false do
      for {compat_case, index} <- Enum.with_index(cases) do
        [input, opts, original, ours, why | marks] = Tuple.to_list(compat_case)
        if marks == [:known_bug], do: Module.put_attribute(__MODULE__, :tag, :known_bug)

        test "#{index}: #{inspect(input)} #{inspect(opts)}" do
          MishkaSlug.CompatCase.check(
            unquote(input),
            unquote(opts),
            unquote(original),
            unquote(ours),
            unquote(why)
          )
        end
      end
    end
  end

  @doc "Checks one case; see the module documentation."
  @spec check(String.t(), keyword(), term(), String.t() | atom(), why()) :: :ok
  def check(input, opts, original, ours, why) do
    expected = expected(ours)

    assert MishkaSlug.slugify(input, opts) == expected
    assert reslug(expected, opts) == expected
    assert is_nil(why) == (original == ours)
    :ok
  end

  defp expected(slug) when is_binary(slug), do: {:ok, slug}
  defp expected(reason), do: {:error, reason}

  defp reslug({:ok, slug}, opts), do: MishkaSlug.slugify(slug, opts)
  defp reslug(error, _opts), do: error
end
