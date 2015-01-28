defmodule EIO.Conn do
  @behaviour :gen_fsm
  defstruct sid: nil, plug_pid: nil, msgs: [], mod: nil

  @reconnect_timeout 3000
  @heartbeat_timeout 5000

  def close(pid, :client) do
    :gen_fsm.send_all_state_event(pid, :client_close)
  end
  def close(pid, :server) do
    :gen_fsm.send_all_state_event(pid, :client_close)
  end

  def upgrade(pid) do
    :gen_fsm.send_event(pid, :upgrade)
  end

  def reply(pid, msg) do
    :gen_fsm.send_event(pid, {:reply, msg})
  end

  def connect(pid) do
    :gen_fsm.send_event(pid, {:connect, self})
  end

  def start_link(args) do
    :gen_fsm.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init({sid, mod}) do
    { :ok, :pause, %__MODULE__{sid: sid, mod: mod}, @reconnect_timeout }
  end

  def pause({:connect, plug_pid}, %__MODULE__{msgs: [h|t]}=sd) do
    send(plug_pid, {:reply, h})
    { :next_state, :pause, %{sd | msgs: t}, @reconnect_timeout }
  end

  def pause({:connect, plug_pid}, sd) do
    { :next_state, :connect, %{sd | plug_pid: plug_pid}, @heartbeat_timeout }
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
    send(sd.plug_pid, {:reply, msg})
    { :next_state, :pause, %{sd | plug_pid: nil}, @reconnect_timeout }
  end

  def connect(:timeout, sd) do
    send(sd.plug_pid, {:reply, :pong})
    { :next_state, :pause, %{sd | plug_pid: nil}, @reconnect_timeout }
  end


  def handle_event(:server_close, _sn, sd) do
    { :stop, {:shutdown, :close}, sd }
  end

  def handle_event(:client_close, _sn, sd) do
    { :stop, {:shutdown, :close}, sd }
  end

  def handle_event(event, sn, sd) do
    IO.inspect {event, sn}
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


  def terminate({:shutdown, reason}, _sn, sd) do
    EIO.Session.delete(sd.sid)
    case reason do
      :upgrade ->
        nil
      :close ->
        spawn fn -> sd.mod.close() end
      :timeout ->
        spawn fn -> sd.mod.close() end
    end
  end

  def terminate(_reason, _sn, sd) do
    spawn fn -> sd.mod.close() end
  end
end
