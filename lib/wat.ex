defmodule Wat do
  @moduledoc """
  Talk-to-... style bot.
  """
  @app :wat

  require Logger

  @doc false
  def finch, do: __MODULE__.Finch

  env_keys = [
    :openai_api_key
  ]

  for key <- env_keys do
    def unquote(key)(), do: Application.fetch_env!(@app, unquote(key))
  end

  def maybe_answer(query) when is_binary(query) do
    similar = list_similar_content(query)

    maybe_answer =
      case similar do
        [] ->
          nil

        similar_content ->
          prelude = [
            %{
              "role" => "system",
              "content" =>
                "You are a helpful GitHub bot answering questions about a ClickHouse adapter written in Elixir named Ch."
            }
          ]

          docs =
            Enum.map(similar_content, fn content -> %{"role" => "user", "content" => content} end)

          query = [%{"role" => "user", "content" => query}]
          messages = prelude ++ docs ++ query
          OpenAI.chat_completion(messages)
      end

    Logger.debug(query: query, similar: similar, answer: maybe_answer)
    maybe_answer
  end

  def list_similar_content(content) when is_binary(content) do
    content
    |> OpenAI.embedding()
    |> list_similar_content()
  end

  defmodule StoredEmbedding do
    @moduledoc false
    use Ecto.Schema

    schema "embeddings" do
      field(:content, :string)
      field(:embedding, :binary)
    end
  end

  def list_similar_content(embedding) do
    import Ecto.Query

    ids = Wat.Index.list_similar_ids(embedding)

    StoredEmbedding
    |> where([e], e.id in ^ids)
    |> select([e], e.content)
    |> Wat.Repo.all()
  end

  # TODO slice up into smaller segments (~one paragraph)
  def embed(content) when is_binary(content) do
    embedding = OpenAI.embedding(content)

    Wat.Repo.transaction(fn ->
      {1, [%{id: id}]} =
        Wat.Repo.insert_all(
          StoredEmbedding,
          [[content: content, embedding: encode_embedding(embedding)]],
          returning: [:id]
        )

      Wat.Index.add_embedding_for_id(id, embedding)
    end)
  end

  @spec encode_embedding([float]) :: binary
  def encode_embedding(embedding) do
    embedding
    |> Enum.map(fn f32 -> <<f32::32-float-little>> end)
    |> IO.iodata_to_binary()
  end

  @spec decode_embedding(binary) :: [float]
  def decode_embedding(<<f32::32-float-little, rest::bytes>>) do
    [f32 | decode_embedding(rest)]
  end

  def decode_embedding(<<>>), do: []
end
