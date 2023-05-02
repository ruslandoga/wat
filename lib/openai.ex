defmodule OpenAI do
  @moduledoc "OpenAI API client to compute embeddings"

  defp url(path), do: Path.join("https://api.openai.com", path)

  defp headers do
    [
      {"content-type", "application/json"},
      {"authorization", "Bearer #{Wat.openai_api_key()}"}
    ]
  end

  @doc false
  def get(path, opts \\ []) do
    req = Finch.build("GET", url(path), headers())
    Finch.request!(req, Wat.finch(), opts)
  end

  @doc false
  def post(path, params, opts \\ []) when is_map(params) do
    body = Jason.encode_to_iodata!(params)
    req = Finch.build("POST", url(path), headers(), body)
    Finch.request!(req, Wat.finch(), opts)
  end

  def embedding(input) do
    %Finch.Response{status: 200, body: body} =
      post("/v1/embeddings", %{"input" => input, "model" => "text-embedding-ada-002"})

    %{"data" => [%{"embedding" => embedding}]} = Jason.decode!(body)
    embedding
  end

  def chat_completion(messages) do
    %Finch.Response{status: 200, body: body} =
      post(
        "/v1/chat/completions",
        %{
          "model" => "gpt-3.5-turbo",
          "messages" => messages,
          "temperature" => 0.7,
          "max_tokens" => 100
        }
      )

    %{"choices" => [%{"message" => %{"content" => content}}]} = Jason.decode!(body)
    content
  end
end
