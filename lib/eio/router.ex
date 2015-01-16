defmodule EIO.Router do
  defmacro __using__(_) do
    quote do
      import Plug.Conn

      def init(opts), do: opts

      def call(%Plug.Conn{path_info: ["engine.io"], method: "POST"}=conn, _) do
        conn = conn |> Plug.Conn.fetch_params(parsers: [:urlencoded], pass: ["*/*"])
        params = conn.params
        eio = params["sid"] |> EIO.Session.check || raise "unknow sid"
        conn
        |> Plug.Conn.read_body
        |> elem(1)
        |> EIO.Parser.decode
        |> Enum.each fn
          {:message, msg} ->
            __MODULE__.message(eio.callback, msg)
          {:close, _} ->
            :gen_fsm.send_all_state_event(eio.pid, :client_close)
          {:ping, _} ->
            :gen_fsm.send_event(eio.pid, {:send_msg, :pong})
          any ->
            IO.puts "FN #{inspect any}"
            send_resp(conn, 200, "ok")
        end
        send_resp(conn, 200, "ok")
      end

      def call(%Plug.Conn{path_info: ["engine.io"]}=conn, _) do
        conn = conn |> Plug.Conn.fetch_params(parsers: [:urlencoded], pass: ["*/*"])
        params = conn.params
        "polling" ==  params["transport"] || raise "no transport"
        case params["sid"] do
          nil ->
            sid = EIO.Session.sid
            r = %{ "sid" => sid, "upgrades" => [], "pingInterval" => 25000, "pingTimeout" => 60000
                 } |> Poison.encode!
            {:ok, pid} = EIO.Supervisor.start_child({sid, __MODULE__})
            __MODULE__.connect(EIO.Polling.Callback.new(pid))
            send_resp(conn, 200, EIO.Parser.encode({:connect, r}))
          sid ->
            eio = EIO.Session.check(sid) || raise "unknow sid"
            :gen_fsm.send_event(eio.pid, {:connect, self})

            socket = conn.adapter |> elem(1) |> elem(1)
            tran =   conn.adapter |> elem(1) |> elem(2)
            :ok = tran.setopts(socket, [active: :once])
            receive do
              {:tcp_closed, ^socket} ->
                :gen_fsm.send_all_state_event(eio.pid, :client_close)
                Plug.Conn.send_resp(conn, 200, "closed")
              {:reply, msg} ->
                Plug.Conn.send_resp(conn, 200, EIO.Parser.encode(msg))
            end
        end
      end
    end
  end
end
