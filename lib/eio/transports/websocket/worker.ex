require Logger
alias Eio.Transports.WebSocket, as: T

defmodule T.Worker do
  defstruct router: nil, session: nil, reason: nil

  def websocket_init(_transport, req, {router, session}) do
    {:ok, :cowboy_req.compact(req), %__MODULE__{router: router, session: session}}
  end

  def websocket_handle({:text, s}, req, %__MODULE__{router: router, session: session}=sd) do
    case T.Parser.decode(s) do
      {:ping, rest} ->
        reply = T.Parser.encode({:pong, rest})
        {:reply, {:text, reply}, req, sd}
      {:upgrade, _} ->
        reply = T.Parser.encode(:pong)
        Eio.Transports.Polling.upgrade(session.worker_pid)
        session = %{session | worker_pid: self, transport: T}
        session |> Eio.Session.save
        {:reply, {:text, reply}, req, %{sd | session: session}}
      {:close, _} ->
        {:shutdown, req, %{sd | reason: "Client closed"}}
      {:message, msg} ->
        spawn fn -> router.message(session, msg) end
        {:ok, req, sd}
    end
  end

  def websocket_handle(data, req, sd) do
    Logger.info "Eio: unknow message received: #{inspect data}"
	  {:ok, req, sd}
  end

  def websocket_info({:close, :server}, req, sd) do
    {:shutdown, req, %{sd | reason: "Server closed"}}
  end

  def websocket_info({:reply, {:message, _}=msg}, req, sd) do
    reply = T.Parser.encode(msg)
    {:reply, {:text, reply}, req, sd}
  end


  def websocket_terminate(_reason, _req, %__MODULE__{router: router, session: session}=sd) do
    reason = sd.reason || "Break"
    Logger.info "Eio: websocket closed, Reason #{reason}."
    session |> Eio.Session.delete
    spawn fn -> router.close(session) end
  end
end
