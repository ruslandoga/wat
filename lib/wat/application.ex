defmodule Wat.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Wat.Repo,
      {Wat.Index, dim: 1536, description: "IDMap,Flat"},
      {Finch, name: Wat.finch(), pools: %{default: [protocol: :http2]}}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Wat.Supervisor)
  end
end
