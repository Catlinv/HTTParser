defmodule HttparserTest do
  use ExUnit.Case
  doctest Httparser

  test "greets the world" do
    assert Httparser.hello() == :world
  end
end
