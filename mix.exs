defmodule Wat.MixProject do
  use Mix.Project

  def project do
    [
      app: :wat,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      releases: releases(),
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {Wat.Application, []}
    ]
  end

  # Specifies which paths to compile per environment.
  # defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(:dev), do: ["lib", "dev"]
  defp elixirc_paths(_env), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nx, "~> 0.5.3", only: [:bench, :test]},
      {:ex_faiss, github: "elixir-nx/ex_faiss", only: [:bench, :test]},
      {:exla, "~> 0.4", only: [:bench, :test]},
      {:finch, "~> 0.16.0"},
      {:ecto_sqlite3, "~> 0.10.0"},
      {:jason, "~> 1.4"},
      {:benchee, "~> 1.1", only: [:bench]},
      {:phoenix, "~> 1.7.2"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.18.16"},
      {:plug_cowboy, "~> 2.5"},
      {:earmark, "~> 1.4"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate --log-migrations-sql"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "assets.setup": ["cmd npm ci --prefix assets"],
      "assets.deploy": [
        "cmd npm ci --prefix assets",
        "cmd npm run deploy:css --prefix assets",
        "cmd npm run deploy:js --prefix assets",
        "phx.digest"
      ]
    ]
  end

  defp releases do
    [wat: [include_executables_for: [:unix]]]
  end
end
