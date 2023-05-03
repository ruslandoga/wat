defmodule Wat do
  @moduledoc """
  Talk-to-... style bot.
  """

  @app :wat

  import Ecto.Query
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

        similar ->
          similar_content = Enum.map(similar, & &1.content)

          prelude = [
            %{
              "role" => "system",
              "content" =>
                String.slice(
                  """
                  You are a helpful GitHub bot answering questions about a Plausible analytics. Answer the following question from the user taking into account following excerpts from the Plausible documentation:

                  #{Enum.join(similar_content, "\n\n")}
                  """,
                  0,
                  5000
                )
            }
          ]

          # knowledge =
          #   Enum.map(similar_content, fn content ->
          #     %{"role" => "system", "content" => content}
          #   end)

          query = [%{"role" => "user", "content" => query}]
          # messages = prelude ++ knowledge ++ query
          messages = prelude ++ query

          sources =
            similar
            |> Enum.map(& &1.source)
            |> Enum.uniq()
            |> Enum.map(fn source -> "- #{source}" end)
            |> Enum.join("\n")

          OpenAI.chat_completion(messages) <> "\n\nSources:\n\n" <> sources
      end

    Logger.debug(query: query, similar: similar, answer: maybe_answer)
    maybe_answer
  end

  def stream_answer(query, f) when is_binary(query) and is_function(f, 1) do
    similar = list_similar_content(query)

    case similar do
      [] ->
        f.(nil)

      similar ->
        similar_content = Enum.map(similar, & &1.content)

        prelude = [
          %{
            "role" => "system",
            "content" =>
              String.slice(
                """
                You are a helpful GitHub bot answering questions about a Plausible analytics. Answer the following question from the user taking into account following excerpts from the Plausible documentation:

                #{Enum.join(similar_content, "\n\n")}
                """,
                0,
                5000
              )
          }
        ]

        # knowledge =
        #   Enum.map(similar_content, fn content ->
        #     %{"role" => "system", "content" => content}
        #   end)

        query = [%{"role" => "user", "content" => query}]
        # messages = prelude ++ knowledge ++ query
        messages = prelude ++ query

        sources =
          similar
          |> Enum.map(& &1.source)
          |> Enum.uniq()
          |> Enum.map(fn source -> "- #{source}" end)
          |> Enum.join("\n")

        sources = "Sources:\n\n" <> sources <> "\n\n"
        f = fn acc -> f.(sources <> acc) end
        OpenAI.chat_completion(messages, f)
    end
  end

  def list_similar_content(content) when is_binary(content) do
    content
    |> OpenAI.embedding()
    |> list_similar_content()
  end

  def list_similar_content(embedding) do
    conn = :persistent_term.get(:read_only_conn, nil) || raise "read only conn not started"
    {:ok, stmt} = Exqlite.Sqlite3.prepare(conn, "select id, embedding from embeddings")

    try do
      {_, ids} =
        calc_max_similarity_ids(
          conn,
          stmt,
          embedding,
          _max_similarities = {-1, -1},
          _corresponding_idx = {-1, -1}
        )

      "embeddings"
      |> where([e], e.id in ^Tuple.to_list(ids))
      |> select([e], map(e, [:source, :content]))
      |> Wat.Repo.all()
    after
      Exqlite.Sqlite3.release(conn, stmt)
    end
  end

  defp calc_max_similarity_ids(conn, stmt, embedding, max_similarities, corresponding_ids) do
    case Exqlite.Sqlite3.multi_step(conn, stmt, 50) do
      {:rows, rows} ->
        {max_similarities, corresponding_ids} =
          naive_search(rows, embedding, max_similarities, corresponding_ids)

        calc_max_similarity_ids(conn, stmt, embedding, max_similarities, corresponding_ids)

      {:done, rows} ->
        naive_search(rows, embedding, max_similarities, corresponding_ids)
    end
  end

  defp naive_search([[id, answer] | rest], query, {m1, m2} = max, {i1, _2} = ids) do
    similarity = cosine_similarity(decode_embedding(answer), query)

    cond do
      similarity > m1 -> naive_search(rest, query, {similarity, m1}, {id, i1})
      similarity > m2 -> naive_search(rest, query, {m1, similarity}, {i1, id})
      true -> naive_search(rest, query, max, ids)
    end
  end

  defp naive_search([], _query, max_similarities, corresponding_ids) do
    {max_similarities, corresponding_ids}
  end

  defp cosine_similarity(a, b), do: cosine_similarity(a, b, 0, 0, 0)

  defp cosine_similarity([x1 | rest1], [x2 | rest2], s1, s2, s12) do
    cosine_similarity(rest1, rest2, x1 * x1 + s1, x2 * x2 + s2, x1 * x2 + s12)
  end

  defp cosine_similarity([], [], s1, s2, s12) do
    s12 / (:math.sqrt(s1) * :math.sqrt(s2))
  end

  defp decode_embedding(<<f32::32-float-little, rest::bytes>>) do
    [f32 | decode_embedding(rest)]
  end

  defp decode_embedding(<<>>), do: []
end
