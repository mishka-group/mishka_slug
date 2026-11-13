# SPDX-FileCopyrightText: 2026 Mishka Group contributors <https://github.com/mishka-group/mishka_slug/graphs/contributors>
#
# SPDX-License-Identifier: Apache-2.0

defmodule MishkaSlug.MixProject do
  use Mix.Project

  @version "0.0.2"
  @source_url "https://github.com/mishka-group/mishka_slug"

  def project do
    [
      app: :mishka_slug,
      name: "Mishka Slug",
      version: @version,
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      description: description(),
      package: package(),
      homepage_url: "https://mishka.tools/cms",
      source_url: @source_url,
      docs: [
        main: "readme",
        source_ref: "v#{@version}",
        extras: ["README.md", "CHANGELOG.md", LICENSE: [title: "License"]],
        source_url: @source_url
      ],
      # `test/support` is compiled in the test env, where `mix ci` runs dialyzer, and it calls
      # `ExUnit`, which is not in the default PLT.
      dialyzer: [plt_add_apps: [:ex_unit]]
    ]
  end

  def cli do
    [preferred_envs: [ci: :test]]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:guarded_struct, "~> 0.1"},
      {:gettext, "~> 1.0"},
      # Only for `MishkaSlug.Change` and `MishkaSlug.Ash`, which are compiled when the host has Ash.
      {:ash, "~> 3.37", optional: true},
      # The property tests use it, and Ash needs it in every env, so it cannot be `only: [:dev, :test]`.
      # Optional: a host without Ash does not fetch it.
      {:stream_data, "~> 1.4", optional: true},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:sobelow, "~> 0.18", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:jump_credo_checks, "~> 0.7", only: [:dev, :test], runtime: false},
      {:ex_slop, "~> 0.4", only: [:dev, :test], runtime: false},
      {:ex_dna, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      # `mix hex.publish` builds the docs with it.
      # `mix test` runs `usage_rules.sync` in a temporary project with it (see `sync_integration`).
      {:usage_rules, "~> 1.2", only: :test},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false}
    ]
  end

  defp description() do
    "URL slugs that keep the original script (Persian, Arabic, Hebrew, Chinese, Japanese, Russian, Hindi, Thai and more), with invisible characters, bidi tricks and mixed-script words taken out, and an Ash change for Mishka CMS."
  end

  defp package() do
    [
      licenses: ["Apache-2.0"],
      maintainers: ["Shahryar Tavakkoli"],
      files:
        ~w(lib priv .formatter.exs mix.exs LICENSE README* CHANGELOG* SECURITY* usage-rules.md usage-rules),
      links: %{
        "Mishka CMS" => "https://mishka.tools/cms",
        "Discord" => "https://discord.gg/m4zdCJjDJg",
        "GitHub" => @source_url,
        "Sponsor" => "https://github.com/sponsors/mishka-group",
        "Contributors" => "#{@source_url}/graphs/contributors"
      }
    ]
  end

  defp aliases() do
    [
      ci: [
        # First: after `compile` Mix has pruned its code path and the Hex archive's task is gone.
        "hex.audit",
        "compile --warnings-as-errors",
        "format --check-formatted",
        "credo --strict",
        "sobelow --config",
        "deps.audit",
        "dialyzer",
        "ex_dna --max-clones 0",
        "test"
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
