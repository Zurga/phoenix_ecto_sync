defmodule PhoenixEctoSync.MixProject do
  use Mix.Project

  @source "https://github.com/Zurga/PhoenixEctoSync"
  def project do
    [
      app: :phoenix_ecto_sync,
      name: "PhoenixEctoSync",
      description: "A set of EctoSync functions specific to Phoenix and LiveView",
      version: "0.2.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.github": :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ],
      package: [
        exclude_patterns: ["priv", ".formatter.exs"],
        maintainers: ["Jim Lemmers"],
        licenses: ["MIT"],
        links: %{
          GitHub: @source
        }
      ],
      # Docs
      name: "PhoenixEctoSync",
      source_url: @source,
      home_page: @source,
      docs: [
        main: "PhoenixEctoSync",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sync, "<= 1.0.0"},
      {:ex_doc, "~> 0.37.2", only: :dev, runtime: false},
      {:credo, "~> 1.6", runtime: false, only: [:dev, :test]},
      {:dialyxir, "~> 1.2", runtime: false, only: [:dev, :test]},
      {:excoveralls, "~> 0.18.0", runtime: false, only: [:test]},
      {:phoenix_live_view, "> 1.0.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
