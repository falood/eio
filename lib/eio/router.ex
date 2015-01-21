defmodule EIO.Router do
  defmacro __using__(opts) do
    quote do
      @eio_plug unquote(opts[:at]) || __MODULE__
      def init(opts), do: opts
      def call(conn, []) do
        opts = [mod: __MODULE__, plug: @eio_plug] |> EIO.Router.init
        EIO.Router.call(conn, opts)
      end
    end
  end

  def init([mod: mod, plug: plug]) do
    {mod, plug}
  end

  def call(conn, {mod, plug}) do
    conn = conn |> Plug.Conn.fetch_params(parsers: [:urlencoded], pass: ["*/*"])
    session = conn.params["sid"] |> EIO.Session.get
    transport = conn.params["transport"]
    not is_nil(transport) || raise "nil transport"
    transport in ["polling", "websocket"] || raise "unknow transport"
    case {conn.method, transport, session} do
      {"GET", _, nil} ->
        # nosid, init polling
        call_init(conn, mod)
      {"POST", "polling", session} ->
        # polling recv, recv_queue.push msg
        call_recv(conn, mod, session)
      {"GET", "polling", session} ->
        # polling conn
        call_conn(conn, mod, session)
      {"GET", "websocket", session} ->
        # upgrade
        call_upgrade(conn, mod, plug, session)
    end
  end

  defp call_recv(conn, mod, session) do
    conn
    |> Plug.Conn.read_body
    |> elem(1)
    |> EIO.Parser.Polling.decode
    |> Enum.each fn
      {:message, msg} ->
        spawn fn -> mod.message(session.callback, msg) end
      {:close, _} ->
        EIO.Conn.close(session.conn_pid, :client)
      {:ping, _} ->
        EIO.Conn.reply(session.conn_pid, :pong)
      any ->
        IO.puts "unknow message: #{inspect any}"
    end
    Plug.Conn.send_resp(conn, 200, "ok")
  end

  defp call_conn(conn, _mod, session) do
    EIO.Conn.connect(session.conn_pid)
    socket = conn.adapter |> elem(1) |> elem(1)
    tran =   conn.adapter |> elem(1) |> elem(2)
    :ok = tran.setopts(socket, [active: :once])
    receive do
      {:tcp_closed, ^socket} ->
        EIO.Conn.close(session.conn_pid, :client)
        Plug.Conn.send_resp(conn, 200, "closed")
      {:reply, msg} ->
        Plug.Conn.send_resp(conn, 200, EIO.Parser.Polling.encode(msg))
    end
  end

  defp call_upgrade(conn, mod, plug, session) do
    ref = Module.concat(plug, conn.scheme |> to_string |> String.upcase)
    {Plug.Adapters.Cowboy.Conn, req} = conn.adapter
    session = %{session | callback: EIO.Callback.new(session.conn_pid, :websocket)}
    :cowboy_websocket.upgrade(req, [listener: ref], __MODULE__, {mod, session})
    Plug.Conn.send_resp(conn, 200, "")
  end

  defp call_init(conn, mod) do
    sid = EIO.Session.new
    r = %{ "sid" => sid, "upgrades" => ["websocket"], "pingInterval" => 25000, "pingTimeout" => 60000
         } |> Poison.encode!
    {:ok, pid} = EIO.Supervisor.start_child({sid, __MODULE__})
    callback = EIO.Callback.new(pid)
    :ets.insert(:eio_polling, {sid, %EIO.Session{sid: sid, conn_pid: pid, callback: callback}})
    spawn fn -> mod.connect(callback) end
    Plug.Conn.send_resp(conn, 200, EIO.Parser.Polling.encode({:connect, r}))
  end


  def websocket_init(_transport, req, sd) do
    {:ok, :cowboy_req.compact(req), sd}
  end

  def websocket_handle({:text, s}, req, {mod, session}=sd) do
    case EIO.Parser.WebSocket.decode(s) do
      {:ping, rest} ->
        reply = EIO.Parser.WebSocket.encode({:pong, rest})
        {:reply, {:text, reply}, req, sd}
      {:upgrade, _} ->
        reply = EIO.Parser.WebSocket.encode(:pong)
        EIO.Conn.upgrade(session.conn_pid)
        {:reply, {:text, reply}, req, sd}
      {:close, _} ->
        EIO.Conn.close(session.conn_pid, :client)
        {:shutdown, req, sd}
      {:message, msg} ->
        spawn fn -> mod.message(session.callback, msg) end
        {:ok, req, sd}
    end
  end

  def websocket_handle(data, req, sd) do
    IO.puts "unknow message: #{inspect data}"
	  {:ok, req, sd}
  end

  def websocket_info(:close, req, sd) do
    {:shutdown, req, sd}
  end

  def websocket_info({:reply, {:message, _}=msg}, req, sd) do
    reply = EIO.Parser.WebSocket.encode(msg)
    {:reply, {:text, reply}, req, sd}
  end

  def websocket_terminate({:error, :closed}, _req, {mod, _session}=_sd) do
    spawn fn -> mod.close() end
  end

  def websocket_terminate({:remote, _code_num, _}, _req, {mod, _session}=_sd) do
    spawn fn -> mod.close() end
  end

  def websocket_terminate(reason, _req, {mod, _session}) do
    spawn fn -> mod.close() end
    IO.puts "websocket closed. Reason: #{inspect reason}"
  end
end
