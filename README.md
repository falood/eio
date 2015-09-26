Eio
========

[engine.io](http://www.engine.io) server for Elixir.

## Usage

use Eio as standalone server

```elixir
defmodule MyApp.Eio do
  use Eio.Router

  def connect(session) do
    session |> EIO.Session.send("connect success")
  end

  def message(session, _msg) do
    session |> EIO.Session.send("message received")
    session |> EIO.Session.close
    ...
  end

  def close(_session) do
    ...
  end
end

Plug.Adapters.Cowboy.http MyApp.Eio, []
```

## TODO

- [X] polling transport
- [X] websocket transport
- [ ] exception
- [ ] version support
- [ ] base64 support
- [ ] jsonp support
- [ ] binary data support
