defmodule OpenAI do
  @moduledoc "Basic OpenAI client"
  alias __MODULE__.API

  def embedding(input) do
    %Finch.Response{status: 200, body: body} =
      API.post!("/v1/embeddings", %{"input" => input, "model" => "text-embedding-ada-002"})

    %{"data" => [%{"embedding" => embedding}]} = Jason.decode!(body)
    embedding
  end

  # TODO stream
  def chat_completion(messages) do
    %Finch.Response{status: 200, body: body} =
      API.post!(
        "/v1/chat/completions",
        %{
          "model" => "gpt-3.5-turbo",
          "messages" => messages,
          "temperature" => 0.7
        },
        receive_timeout: :timer.minutes(2)
      )

    %{"choices" => [%{"message" => %{"content" => content}}]} = Jason.decode!(body)
    content
  end

  def chat_completion(messages, f) when is_function(f, 1) do
    API.stream(
      "/v1/chat/completions",
      %{
        "model" => "gpt-3.5-turbo",
        "messages" => messages,
        "temperature" => 0.7,
        "stream" => true
      },
      f,
      receive_timeout: :timer.minutes(2)
    )
  end
end
