defmodule OpenAI.API do
  @moduledoc false

  defp url(path), do: Path.join("https://api.openai.com", path)

  defp headers do
    [
      {"content-type", "application/json"},
      {"authorization", "Bearer #{Wat.openai_api_key()}"}
    ]
  end

  def get!(path, opts \\ []) do
    req = Finch.build("GET", url(path), headers())
    Finch.request!(req, Wat.finch(), opts)
  end

  def post!(path, params, opts \\ []) do
    body = Jason.encode_to_iodata!(params)
    req = Finch.build("POST", url(path), headers(), body)
    Finch.request!(req, Wat.finch(), opts)
  end
end
