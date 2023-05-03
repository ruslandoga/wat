defmodule Wat.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Wat.Repo,
      # {Wat.Embeddings.FaissIndex, dim: 1536, description: "IDMap,Flat"},
      {Finch, name: Wat.finch(), pools: %{default: [protocol: :http2]}}
    ]

    database = Keyword.fetch!(Wat.Repo.config(), :database)
    {:ok, read_only_conn} = Exqlite.Sqlite3.open(database)
    :persistent_term.put(:read_only_conn, read_only_conn)

    Supervisor.start_link(children, strategy: :one_for_one, name: Wat.Supervisor)
  end
end
