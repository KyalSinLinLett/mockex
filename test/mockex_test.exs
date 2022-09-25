defmodule MockexTest do
  use ExUnit.Case, async: false
  import Mockex

  test "mock the String.at/2 function" do
    use_mock String,
      at: fn _, _ -> "mock response here" end do
      assert String.at("hello", 2) == "mock response here"
    end
  end

  test "mock testing several modules and their functions" do
    use_mocks([
      {Map, [],
       [
         get: fn %{}, "key" -> "value" end
       ]},
      {String, [],
       [
         reverse: fn _ -> :reversed end,
         length: fn _ -> :some_length end
       ]}
    ]) do
      assert Map.get(%{}, "key") == "value"
      assert String.reverse(3) == :reversed
      assert String.length(3) == :some_length
    end
  end
end
