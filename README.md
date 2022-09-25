# Mockex

Mockex is a lightweight mocking library for elixir. Create simple mocks for external/third-party calls or mock websocket servers with custom listeners and responses.

## Reference/Documentation
Run the **doc/index.html** file with live server.

## Test
Run `mix test`

## Installation

Add `mockex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:mockex, git: "https://github.com/KyalSinLinLett/mockex", branch: "develop"}
  ]
end
```
Run `mix deps.get`