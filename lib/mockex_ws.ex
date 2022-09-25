defmodule Mockex.MockWebsocketServerBehaviour do
  @moduledoc """
  Behaviour for implementing custom mock websocket
  server for testing purposed.

  ## Example

      # create a new file test/mock_ws.ex to define the Mock Websocket Server
      defmodule CustomMockWsServer do
        import Mockex
        @behaviour Mockex.MockWebsocketServerBehaviour

        @impl true
        def start_server do
          start_mock_ws(fn -> handle_incoming_messages() end)
        end

        @impl true
        def handle_incoming_messages do
          add_listeners do
            # sample custom incoming message and custom response
            # caller refers to the client's PID - sent with self() from client side
            {:hi_from_client, caller} ->
              send(caller, :hi_from_server)

            {:hi_from_client2, caller} ->
              send(caller, :hi_from_server2)

            {:hi_from_client3, caller} ->
              send(caller, :hi_from_server3)

            # a more generic example
            {message, caller} ->
              send(caller, message)

            default ->
              IO.puts "error"
          end

          handle_incoming_messages() # to keep listener open
        end
      end

      # in the test/test_helper.exs, add the following line at the top of the file

      Code.require_file("test/mock_ws.ex")

      # in the testsuite
      # start the server during each test case execution

      setup do
        {:ok, ws_pid} = CustomMockWsServer.start_server()
        %{ws_pid: ws_pid}
      end

      test "test ws client push event to the CustomMockWsServer", %{ws_pid: ws_pid} do
        use_mock SocketClient,
          push: fn message -> push_to_ws(ws_pid, {message, self()}) end do
          SocketClient.push(:hi_from_client)
          assert_receive :hi_from_server, 2000 # timeout is 2000ms
        end
      end

      #### OR ####

      # start the server for use throughout all testcases

      setup_all do
        {:ok, ws_pid} = CustomMockWsServer.start_server()
        %{ws_pid: ws_pid}
      end

      test "test ws client push event to the CustomMockWsServer", %{ws_pid: ws_pid} do
        use_mock SocketClient,
          push: fn message -> push_to_ws(ws_pid, {message, self()}) end do

          # push to server 1
          SocketClient.push(:hi_from_client)
          assert_receive :hi_from_server, 2000 # timeout is 2000ms

          # push to server 2
          SocketClient.push(:hi_from_client2)
          assert_receive :hi_from_server2, 2000 # timeout is 2000ms

          # push to server 3
          SocketClient.push(:hi_from_client3)
          assert_receive :hi_from_server3, 2000 # timeout is 2000ms
        end
      end

  """
  @callback start_server :: {:ok, pid()}
  @callback handle_incoming_messages :: nil
end
