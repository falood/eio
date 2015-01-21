EIO
========

ELixir server of [engine.io](http://www.engine.io)

## Usage

use EIO as standalone server

```elixir
defmodule MyApp.EIO do
  use EIO.Router

  def connect(eio) do
    eio.send("connect success")
  end

  def message(eio, msg) do
    eio.send("message received")
    eio.close()
    ...
  end

  def close do
    ...
  end
end

Plug.Adapters.Cowboy.http MyApp.EIO, []
```

use EIO as phoenix handler

```elixir
defmodule MyApp.EIO do
  use EIO.Router, at: MyApp.Endpoint

  def connect(eio) do
    eio.send("connect success")
  end

  def message(eio, msg) do
    eio.send("message received")
    ...
  end

  def close do
    ...
  end
end

defmodule MyApp.Endpoint do
  use Phoenix.Endpoint, otp_app: :phonenix_maru

  plug EIO.Plugs.Forword, to: MyApp.EIO
  ...
  plug :router, MyApp.Endpoint
end
```

## TODO

- [X] polling transport
- [X] websocket transport
- [ ] exception
- [ ] version support
- [ ] base64 support
- [ ] binary data support
