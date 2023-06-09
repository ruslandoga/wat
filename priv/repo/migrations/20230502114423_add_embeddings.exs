defmodule Wat.Repo.Migrations.AddEmbeddings do
  use Ecto.Migration

  def change do
    create table("embeddings", options: "STRICT") do
      add :source, :text, null: false
      add :content, :text, null: false
      add :embedding, :blob, null: false
    end
  end
end
