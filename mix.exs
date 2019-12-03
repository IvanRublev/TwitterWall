defmodule TwitterWall.MixProject do
  use Mix.Project

  def project do
    [
      app: :twitter_wall,
      version: "0.1.0",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      elixirc_options: elixirc_options(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [plt_add_deps: :transitive]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {TwitterWall.Application, []},
      extra_applications: [:logger, :runtime_tools, :confex, :hackney]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies compiler flags per environment.
  defp elixirc_options(:test), do: []
  defp elixirc_options(_), do: [warnings_as_errors: true]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4.10"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:phoenix_live_view, "~> 0.4"},
      # live view tests
      {:floki, ">= 0.0.0", only: :test},
      # HTTP client
      {:tesla, "~> 1.2.1"},
      # OAuth 2 signed header generator
      {:oauther, "~> 1.1"},
      # JWT tokens verification
      {:joken, "~> 2.1.0"},
      # CORS headers support
      {:corsica, "~> 1.1"},
      # Time calculations
      {:timex, "~> 3.6"},
      # Automatic test run on file save
      {:mix_test_watch, "~> 0.8", only: :dev, runtime: false},
      # Behaviour mocking
      {:mox, "~> 0.5"},
      # Reduce dependency injection boilerplate
      {:knigge, "~> 1.0"},
      # Code coverage into single html page generator
      {:excoveralls, "~> 0.12", only: [:dev, :test]},
      # Linter
      {:credo, "~> 1.1", only: [:dev, :test], runtime: false},
      # Security-focused static analysis for the Phoenix framework
      {:sobelow, "~> 0.8"},
      # Mix tasks to simplify use of Dialyzer for typespec checks
      {:dialyxir, "~> 0.5", only: [:dev], runtime: false},
      # Runtime configuration with environment variables
      {:confex, "~> 3.4"},
      # Release framework
      {:distillery, "~> 2.1", runtime: false}
    ]
  end
end
