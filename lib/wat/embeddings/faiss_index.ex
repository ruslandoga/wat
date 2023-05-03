# defmodule Wat.Embeddings.FaissIndex do
#   @moduledoc """
#   Faiss index in-memory, access serialized by a genserver
#   """

#   use GenServer

#   def start_link(opts \\ []) do
#     GenServer.start_link(__MODULE__, opts, name: __MODULE__)
#   end

#   def add_embedding_for_id(id, embedding) do
#     checkout(fn index ->
#       ExFaiss.Index.add_with_ids(index, Nx.tensor([embedding]), Nx.tensor([id]))
#     end)
#   end

#   def list_similar_ids(embedding, count \\ 2) do
#     checkout(fn index ->
#       %{labels: labels} = ExFaiss.Index.search(index, Nx.tensor([embedding]), count)
#       labels |> Nx.to_flat_list() |> Enum.reject(fn label -> label == -1 end)
#     end)
#   end

#   @doc false
#   def checkout(f) when is_function(f, 1) do
#     case GenServer.call(__MODULE__, :checkout) do
#       {:ok, index} ->
#         try do
#           f.(index)
#         after
#           checkin()
#         end

#       # TODO queue, maybe use nimble_pool
#       {:error, :busy} ->
#         raise "index is busy"
#     end
#   end

#   @doc false
#   def checkin, do: GenServer.call(__MODULE__, :checkin)

#   # TODO continue
#   @impl true
#   def init(opts) do
#     dim = opts[:dim] || 1536
#     description = opts[:description] || "IDMap,Flat"
#     %ExFaiss.Index{} = index = ExFaiss.Index.new(dim, description)
#     {:ok, %{caller: nil, index: index}}
#   end

#   @impl true
#   def handle_call(:checkout, {pid, _}, %{caller: nil, index: index} = state) do
#     Process.monitor(pid)
#     {:reply, {:ok, index}, %{state | caller: pid}}
#   end

#   def handle_call(:checkout, _from, state) do
#     {:reply, {:error, :busy}, state}
#   end

#   def handle_call(:checkin, {pid, _}, %{caller: pid} = state) do
#     {:reply, :ok, %{state | caller: nil}}
#   end
# end
