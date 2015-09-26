defmodule Eio.Router do
  defmacro __using__(_) do
    quote do
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(%Macro.Env{module: module}=env) do
    pipeline = [
      {Plug.Parsers, [parsers: [:urlencoded], pass: ["*/*"], json_decoder: Poison], true},
      {Eio.Router.Prepare, [], true},
      {Eio.Transports.Polling.Router, [router: module], true},
      {Eio.Transports.WebSocket.Router, [router: module], true},
    ] |> Enum.reverse
    {conn, body} = Plug.Builder.compile(env, pipeline, [])

    quote do
      def init(_), do: []
      def call(unquote(conn), _) do
        unquote(body)
      end
    end
  end

end

defmodule Eio.Router.Prepare do
  alias Plug.Conn

  def init(_), do: []

  def call(%Conn{params: params}=conn, []) do
    transport = conn.params["transport"]
    not is_nil(transport) || raise "nil transport"
    transport in ["polling", "websocket"] || raise "unknow transport"
    transport = transport |> String.to_atom
    session = params["sid"] |> Eio.Session.get
    conn
    |> Conn.put_private(:eio_session, session)
    |> Conn.put_private(:eio_transport, transport)
  end
end
