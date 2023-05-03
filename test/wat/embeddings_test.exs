defmodule Wat.EmbeddingsTest do
  use ExUnit.Case

  describe "search" do
    test "faiss" do
      %ExFaiss.Index{} = index = ExFaiss.Index.new(_dim = 1536, "IDMap,Flat")

      ^index =
        ExFaiss.Index.add_with_ids(
          index,
          _embeddings =
            Nx.tensor([
              answer(
                "Ding Liren defeats Ian Nepomniachtchi to win the World Chess Championship."
              ),
              answer(
                "SpaceX launches the first test flight of Starship, the largest and most powerful launch vehicle to ever fly, from Starbase in South Texas. The vehicle successfully launched but lost control and the flight was explosively terminated four minutes after liftoff."
              ),
              answer("American retailer Bed Bath & Beyond files for Chapter 11 bankruptcy")
            ]),
          _ids = Nx.tensor([1, 2, 3])
        )

      assert result =
               ExFaiss.Index.search(
                 index,
                 _query = Nx.tensor([query("what's the biggest rocket ever built?")]),
                 _k = 3
               )

      assert result.distances ==
               Nx.tensor([[0.31625497341156006, 0.5950052738189697, 0.6141740083694458]])

      assert result.labels == Nx.tensor([[2, 1, 3]])
    end

    test "naive" do
      index = [
        {1, answer("Ding Liren defeats Ian Nepomniachtchi to win the World Chess Championship.")},
        {2,
         answer(
           "SpaceX launches the first test flight of Starship, the largest and most powerful launch vehicle to ever fly, from Starbase in South Texas. The vehicle successfully launched but lost control and the flight was explosively terminated four minutes after liftoff."
         )},
        {3, answer("American retailer Bed Bath & Beyond files for Chapter 11 bankruptcy")}
      ]

      assert {similarities, labels} =
               naive_search(index, query("what's the biggest rocket ever built?"))

      assert similarities == {0.8418724987005781, 0.702497387836152, 0.6929130061709691}
      distances = similarities |> Tuple.to_list() |> Enum.map(fn similarity -> 1 - similarity end)
      assert distances == [0.15812750129942188, 0.297502612163848, 0.30708699382903093]
      distances_x2 = Enum.map(distances, fn d -> d * 2 end)
      assert distances_x2 == [0.31625500259884376, 0.595005224327696, 0.6141739876580619]
      assert labels == {2, 1, 3}
    end

    defp naive_search(index, query) do
      naive_search(
        index,
        query,
        _max_similarities = {-1, -1, -1},
        _corresponding_ids = {-1, -1, -1}
      )
    end

    defp naive_search(
           [{id, answer} | rest],
           query,
           {m1, m2, m3} = max_similarities,
           {i1, i2, i3} = corresponding_ids
         ) do
      similarity = cosine_similarity(answer, query)

      cond do
        similarity > m1 -> naive_search(rest, query, {similarity, m1, m2}, {id, i1, i2})
        similarity > m2 -> naive_search(rest, query, {m1, similarity, m2}, {i1, id, i2})
        similarity > m3 -> naive_search(rest, query, {m1, m2, similarity}, {i1, i2, id})
        true -> naive_search(rest, query, max_similarities, corresponding_ids)
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
  end

  defp answer(content) do
    Map.fetch!(json("answers"), content)
  end

  defp query(content) do
    Map.fetch!(json("queries"), content)
  end

  defp json(name) do
    Path.join("test/priv", name <> ".json")
    |> File.read!()
    |> Jason.decode!()
  end
end
