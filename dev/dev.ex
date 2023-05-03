defmodule Dev do
  @moduledoc false
  import Ecto.Query

  def embed_docs(path \\ "docs") do
    docs = Path.wildcard(Path.join(path, "/**/*")) -- ["#{path}/proxy", "#{path}/proxy/guides"]
    len = length(docs)

    docs
    |> Enum.with_index(1)
    |> Enum.each(fn {doc, ix} ->
      IO.puts("#{ix}/#{len}: #{doc}")
      full_doc = File.read!(doc)
      segmented_docs = full_doc |> String.split("\n# ", trim: true) |> Enum.map(&String.trim/1)
      source = "https://plausible.io/#{String.replace_trailing(doc, ".md", "")}"

      to_embed =
        case segmented_docs do
          [_] -> [full_doc]
          [_ | _] -> [full_doc | segmented_docs]
        end

      Enum.each(to_embed, fn doc ->
        unless already_embedded?(doc) do
          embedding = OpenAI.embedding(doc)
          IO.puts(doc)

          Wat.Repo.insert_all(StoredEmbedding, [
            [embedding: encode_embedding(embedding), source: source, content: doc]
          ])
        end
      end)
    end)
  end

  defp already_embedded?(content) do
    StoredEmbedding
    |> where(content: ^content)
    |> Wat.Repo.exists?()
  end

  # TODO slice up into smaller segments (~one paragraph)
  def embed(content) when is_binary(content) do
    embedding = OpenAI.embedding(content)

    # Wat.Repo.transaction(fn ->
    {1, [%{id: _id}]} =
      Wat.Repo.insert_all(
        StoredEmbedding,
        [[content: content, embedding: encode_embedding(embedding)]],
        returning: [:id]
      )

    # Wat.Index.add_embedding_for_id(id, embedding)
    # end)
  end

  @spec encode_embedding([float]) :: binary
  def encode_embedding(embedding) do
    embedding
    |> Enum.map(fn f32 -> <<f32::32-float-little>> end)
    |> IO.iodata_to_binary()
  end

  defmodule StoredEmbedding do
    @moduledoc false
    use Ecto.Schema

    schema "embeddings" do
      field(:source, :string)
      field(:content, :string)
      field(:embedding, :binary)
    end
  end
end
