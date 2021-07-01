defmodule TwitterWall.MixProject do
  use Mix.Project

  def project do
    [
      app: :twitter_wall,
      version: "0.2." <> File.read!("BUILD.MD"),
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {TwitterWall.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.14.1", only: [:dev, :test], runtime: false},
      {:ex_check, ">= 0.0.0", only: :test, runtime: false},
      {:credo, "~> 1.5", only: :test, runtime: false},
      {:sobelow, "~> 0.11.1", only: :test, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :test, runtime: false},
      {:bypass, "~> 2.1", only: :test},
      {:mox, "~> 1.0", only: :test},
      {:knigge, "~> 1.4"},
      {:phoenix, "~> 1.5.9"},
      {:phoenix_live_view, "~> 0.15"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_html, "~> 2.14"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:phoenix_live_dashboard, "~> 0.4"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:finch, "~> 0.8.0"},
      {:oauther, github: "tobstarr/oauther"},
      {:joken, "~> 2.3"},
      {:corsica, "~> 1.1"},
      {:timex, "~> 3.7"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "cmd yarn install --cwd assets"],
      bearer_token: [
        "run -e 'TwitterWallWeb.AuthToken.generate_and_sign!(%{\"exp\" => Joken.current_time() + 60 * 5, \"tweet_count\" => 4}) |> IO.puts()'"
      ]
    ]
  end

  def preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test,
      "coveralls.travis": :test,
      check: :test,
      credo: :test,
      sobelow: :test
    ]
  end
end
