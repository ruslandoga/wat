defmodule Wat.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Wat.Repo,
      # {Wat.Embeddings.FaissIndex, dim: 1536, description: "IDMap,Flat"},
      {Phoenix.PubSub, name: Wat.PubSub},
      {Finch, name: Wat.finch(), pools: %{default: [protocol: :http2]}},
      WatWeb.Endpoint
    ]

    database = Keyword.fetch!(Wat.Repo.config(), :database)
    {:ok, read_only_conn} = Exqlite.Sqlite3.open(database)
    :persistent_term.put(:read_only_conn, read_only_conn)

    Supervisor.start_link(children, strategy: :one_for_one, name: Wat.Supervisor)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
