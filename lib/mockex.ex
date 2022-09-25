defmodule Mockex do
  @moduledoc """
  Mockex is a lightweight mocking library for elixir.
  Create simple mocks for external/third-party calls or
  mock websocket servers with custom listeners and responses.
  """

  @doc """
  Macro used to define a mock. Provide the Module, function to be mocked, and the expectation.
  Then, make function calls as you normally would.

  ## Examples

      test "mock the String.at/2 function" do
        use_mock String,
          at: fn _, _ -> "mock response here" end do
          assert String.at("hello", 2) == "mock response here"
        end
      end

  """
  defmacro use_mock(mock_module, opts \\ [], mocks, do: test) do
    quote do
      unquote(__MODULE__).use_mocks(
        [{unquote(mock_module), unquote(opts), unquote(mocks)}],
        do: unquote(test)
      )
    end
  end

  @doc """
  Macro used to define several mock modules before each test.
  Provide the Module, function to be mocked, and the expectation.
  Then, make function calls as you normally would.

  ## Examples

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



  """
  defmacro use_mocks(mocks, do: test) do
    quote do
      mocked_modules = create_mocks(unquote(mocks))

      try do
        unquote(test)
      after
        for m <- mocked_modules, do: :meck.unload(m)
      end
    end
  end

  @doc """
  Macro to add custom listeners for the mock websocket server
  incoming messages and define mock responses.
  """
  defmacro add_listeners(do: receive_block) do
    quote do
      receive do
        unquote(receive_block)
      end
    end
  end

  @doc """
  Macro to setup several mocks before each test case.
  """
  defmacro setup_mock(mocks, do: setup_block) do
    quote do
      setup do
        create_mocks(unquote(mocks))

        on_exit(fn ->
          :meck.unload()
        end)

        unquote(setup_block)
      end
    end
  end

  @doc """
  Start a mock websocket server.
  """
  def start_mock_ws(listener) do
    Task.start_link(listener)
  end

  @doc """
  Push a message to the mock websocket server.
  """
  @spec push_to_ws(pid(), tuple()) :: :noconnect | :nosuspend | :ok
  def push_to_ws(ws_pid, message) do
    Process.send(ws_pid, message, [])
  end

  ########### PRIVATE MACROS AND FUNCTIONS #############

  @doc false
  defmacro create_mocks(mocks) do
    quote do
      Enum.reduce(unquote(mocks), [], fn {m, opts, mock_fns}, ms ->
        unless m in ms do
          try do
            if :meck.validate(m), do: :meck.unload(m)
          rescue
            e in ErlangError -> :ok
          end

          unquote(__MODULE__).expect_mock(m, mock_fns)
          true = :meck.validate(m)

          [m | ms] |> Enum.uniq()
        end
      end)
    end
  end

  @doc false
  def expect_mock(_, []), do: :ok

  @doc false
  def expect_mock(mock_module, [{fn_name, value} | tail]) do
    :meck.expect(mock_module, fn_name, value)
    expect_mock(mock_module, tail)
  end
end
