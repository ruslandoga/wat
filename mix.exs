defmodule Wat.MixProject do
  use Mix.Project

  def project do
    [
      app: :wat,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
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
      {:benchee, "~> 1.1", only: [:bench]}
    ]
  end
end
