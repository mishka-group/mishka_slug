# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.UsageRulesTest do
  @moduledoc """
  The examples in `usage-rules.md` are run against the real code, so the rules an agent reads
  never drift from what `MishkaSlug.slugify/2` returns.
  """
  use ExUnit.Case, async: true

  @rules Path.expand("../../usage-rules.md", __DIR__)

  # A call of the form `MishkaSlug.slugify(...)  #=> result`, the result on the same or next line.
  @example ~r/^(MishkaSlug\.slugify!?\(.*?\))[ \t]*\n?[ \t]*#=>[ \t]*(.+)$/m

  defp examples do
    Regex.scan(@example, File.read!(@rules), capture: :all_but_first)
  end

  test "the rules carry examples to check" do
    assert length(examples()) >= 30
  end

  test "every example in usage-rules.md returns what it says" do
    for [call, expected] <- examples() do
      {actual, _binding} = Code.eval_string(call)
      {expected, _binding} = Code.eval_string(expected)

      assert actual == expected,
             "#{call} returned #{inspect(actual)}, the rules say #{inspect(expected)}"
    end
  end
end
