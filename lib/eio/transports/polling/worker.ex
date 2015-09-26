require Logger
alias Eio.Transports.Polling, as: T

defmodule T.Worker do
  defstruct sid: nil, router: nil, router_pid: nil, msgs: [], halted: false

  @behaviour :gen_fsm
  @reconnect_timeout 3000
  @heartbeat_timeout 5000

  def start_link(args) do
    :gen_fsm.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init({sid, router}) do
    { :ok, :pause, %__MODULE__{sid: sid, router: router}, @reconnect_timeout }
  end

  def pause({:connect, router_pid}, %__MODULE__{msgs: msgs, halted: true}=sd) do
    send(router_pid, {:reply, msgs ++ [:close]})
    { :stop, {:shutdown, {:close, :server}}, sd }
  end

  def pause({:connect, router_pid}, %__MODULE__{msgs: []}=sd) do
    { :next_state, :connect, %{sd | router_pid: router_pid}, @heartbeat_timeout }
  end

  def pause({:connect, router_pid}, %__MODULE__{msgs: msgs}=sd) do
    send(router_pid, {:reply, msgs})
    { :next_state, :pause, %{sd | msgs: []}, @reconnect_timeout }
  end

  def pause({:reply, data}, sd) do
    { :next_state, :pause, %{sd | msgs: sd.msgs ++ [data]}, @reconnect_timeout }
  end

  def pause(:timeout, sd) do
    { :stop, {:shutdown, :timeout}, sd }
  end

  def pause(:upgrade, sd) do
    { :stop, {:shutdown, :upgrade}, sd }
  end

  def connect({:reply, msg}, sd) do
    send(sd.router_pid, {:reply, msg})
    { :next_state, :pause, %{sd | router_pid: nil}, @reconnect_timeout }
  end

  def connect(:timeout, sd) do
    send(sd.router_pid, {:reply, :pong})
    { :next_state, :pause, %{sd | router_pid: nil}, @reconnect_timeout }
  end


  def handle_event({:close, :server}, :pause, sd) do
    { :next_state, :pause, %{sd | halted: true}, @reconnect_timeout }
  end

  def handle_event({:close, :client}, :pause, sd) do
    { :stop, {:shutdown, {:close, :client}}, sd }
  end

  def handle_event({:close, x}, :connect, sd) when x in [:client, :server] do
    send(sd.router_pid, {:reply, :close})
    { :stop, {:shutdown, {:close, x}}, sd }
  end

  def handle_event(event, sn, sd) do
    Logger.info "Eio: Unknown polling event #{inspect event}"
    { :next_state, sn, sd }
  end

  def handle_sync_event(_event, _from, sn, sd) do
    { :next_state, sn, sd }
  end

  def handle_info(_info, sn, sd) do
    { :next_state, sn, sd }
  end

  def code_change(_old_vsn, sn, sd, _extra) do
    {:ok, sn, sd}
  end


  def terminate({:shutdown, :upgrade}, _sn, _sd) do
    Logger.info "Eio: Polling protocol upgraded"
    nil
  end

  def terminate({:shutdown, {:close, x}}, _sn, sd) when x in [:client, :server] do
    Logger.info "Eio: Polling closed by #{x}"
    session = sd.sid |> Eio.Session.get
    sd.sid |> Eio.Session.delete
    spawn fn -> sd.router.close(session) end
  end

  def terminate(reason, _sn, sd) do
    Logger.error "Eio: Polling closed, reason: #{inspect reason}"
    session = sd.sid |> Eio.Session.get
    sd.sid |> Eio.Session.delete
    spawn fn -> sd.router.close(session) end
  end
end
