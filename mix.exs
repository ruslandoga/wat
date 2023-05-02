defmodule Wat.MixProject do
  use Mix.Project

  def project do
    [
      app: :wat,
      version: "0.1.0",
      elixir: "~> 1.14",
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

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nx, "~> 0.5.3"},
      {:ex_faiss, github: "elixir-nx/ex_faiss"},
      {:exla, "~> 0.4"},
      {:finch, "~> 0.16.0"},
      {:ecto_sqlite3, "~> 0.10.0"},
      {:jason, "~> 1.4"}
    ]
  end
end
