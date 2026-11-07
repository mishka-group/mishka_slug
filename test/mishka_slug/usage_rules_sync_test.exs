# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.UsageRulesSyncTest do
  @moduledoc """
  Runs the real `mix usage_rules.sync` (usage_rules 1.2) in a temporary project that has
  `mishka_slug` as a path dependency, and checks the generated file holds the rules.

  It needs the network (`mix deps.get`), so it is excluded by default:
  `mix test --include sync_integration`.
  """
  use ExUnit.Case

  @moduletag :sync_integration
  @moduletag timeout: :timer.minutes(10)
  @project_root File.cwd!()

  defp mix_exs(usage_rules) do
    """
    defmodule TestProject.MixProject do
      use Mix.Project

      def project do
        [
          app: :test_project,
          version: "0.1.0",
          elixir: "~> 1.20",
          deps: [
            {:mishka_slug, path: "#{@project_root}"},
            {:usage_rules, "~> 1.2", only: :dev}
          ],
          usage_rules: #{usage_rules}
        ]
      end
    end
    """
  end

  defp mix(dir, args),
    do: System.cmd("mix", args, cd: dir, stderr_to_stdout: true, env: [{"MIX_ENV", "dev"}])

  defp sync!(dir, usage_rules) do
    File.write!(Path.join(dir, "mix.exs"), mix_exs(usage_rules))

    {_output, 0} = mix(dir, ["deps.get"])

    {_output, 0} = mix(dir, ["usage_rules.sync", "--yes"])
    File.read!(Path.join(dir, "CLAUDE.md"))
  end

  setup do
    dir = Path.join(System.tmp_dir!(), "usage_rules_sync_#{System.unique_integer([:positive])}")
    File.mkdir_p!(Path.join(dir, "lib"))
    File.write!(Path.join(dir, "lib/test_project.ex"), "defmodule TestProject do\nend\n")
    on_exit(fn -> File.rm_rf!(dir) end)
    {:ok, dir: dir}
  end

  test "usage_rules: [:mishka_slug] writes the main rules", %{dir: dir} do
    content = sync!(dir, ~s|[file: "CLAUDE.md", usage_rules: [:mishka_slug]]|)

    assert content =~ "<!-- mishka_slug-start -->"
    assert content =~ "MishkaSlug.slugify"
  end

  test "sub_rules names the Ash and configuration files", %{dir: dir} do
    content =
      sync!(dir, """
      [file: "CLAUDE.md", usage_rules: [{:mishka_slug, sub_rules: ["ash", "configuration"]}]]
      """)

    assert content =~ "<!-- mishka_slug:ash-start -->"
    assert content =~ "<!-- mishka_slug:configuration-start -->"
  end
end
