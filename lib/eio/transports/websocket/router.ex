alias Eio.Transports.WebSocket, as: T

defmodule T.Router do
  alias Plug.Conn

  def init(opts) do
    opts[:router]
  end

  def call(%Conn{method: "GET", private: %{eio_session: session, eio_transport: :websocket}}=conn, router) do
    listener = Module.concat(router, conn.scheme |> to_string |> String.upcase)
    {Plug.Adapters.Cowboy.Conn, req} = conn.adapter
    # session = %{session | transport: T}
    :cowboy_websocket.upgrade(req, [listener: listener], T.Worker, {router, session})
    Plug.Conn.send_resp(conn, 200, "")
  end

  def call(conn, _) do
    conn
  end
end
