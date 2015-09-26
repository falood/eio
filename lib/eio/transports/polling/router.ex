require Logger
alias Eio.Transports.Polling, as: T

defmodule T.Router do
  alias Plug.Conn

  def init(opts) do
    opts[:router]
  end

  # Initialization connection
  def call(%Conn{method: "GET", private: %{eio_session: nil, eio_transport: :polling}}=conn, router) do
    sid = Eio.Session.generate_id
    r = %{
      "sid" => sid,
      "upgrades" => ["websocket"],
      # "upgrades" => [],
      "pingInterval" => 25000,
      "pingTimeout" => 60000,
    } |> Poison.encode!
    {:ok , pid} = T.start_worker(sid, router)
    session = %Eio.Session{
      sid: sid,
      worker_pid: pid,
      transport: T,
    }
    session |> Eio.Session.save
    spawn fn -> router.connect(session) end
    Conn.send_resp(conn, 200, T.Parser.encode({:connect, r}))
  end

  # Polling connection, waiting for server message
  def call(%Conn{method: "GET", private: %{eio_session: session, eio_transport: :polling}}=conn, _router) do
    socket = conn.adapter |> elem(1) |> elem(1)
    tran   = conn.adapter |> elem(1) |> elem(2)
    :ok = tran.setopts(socket, [active: :once])
    T.connect(session.worker_pid)
    receive do
      # :server_closed ->
      #   Conn.send_resp(conn, 200, "close")
      {:tcp_closed, ^socket} ->
        T.close(session.worker_pid, :client)
        Conn.send_resp(conn, 200, "close")
      {:reply, msg} ->
        Conn.send_resp(conn, 200, T.Parser.encode(msg))
    end
  end

  # Push request, push new message to server
  def call(%Conn{method: "POST", private: %{eio_session: session, eio_transport: :polling}}=conn, router) do
    conn
    |> Conn.read_body
    |> elem(1)
    |> T.Parser.decode
    |> Enum.each fn
      {:message, msg} ->
        spawn fn -> router.message(session, msg) end
      {:close, _} ->
        T.close(session.worker_pid, :client)
      {:ping, _} ->
        T.reply(session.worker_pid, :pong)
      any ->
        Logger.info "Eio: unknown message received: #{inspect any}"
    end
    Conn.send_resp(conn, 200, "ok")
  end

  def call(conn, _), do: conn
end
