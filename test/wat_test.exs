defmodule WatTest do
  use ExUnit.Case
  doctest Wat

  test "greets the world" do
    assert Wat.hello() == :world
  end
end
