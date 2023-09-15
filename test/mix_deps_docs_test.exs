defmodule MixDepsDocsTest do
  use ExUnit.Case
  doctest MixDepsDocs

  test "greets the world" do
    assert MixDepsDocs.hello() == :world
  end
end
