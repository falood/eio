defmodule EIO.Polling.Connect do
  @behaviour :gen_fsm
  defstruct sid: nil, plug_pid: nil, msgs: [], mod: nil

  @reconnect_timeout 3000
  @heartbeat_timeout 5000

  def start_link(args) do
    :gen_fsm.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init({sid, mod}) do
    callback = EIO.Polling.Callback.new(self)
    :ets.insert(:eio_polling, {sid, %EIO.Session{sid: sid, pid: self, callback: callback}})
    { :ok, :pause, %__MODULE__{sid: sid, mod: mod}, @reconnect_timeout }
  end

  def pause({:connect, plug_pid}, %__MODULE__{msgs: [h|t]}=sd) do
    send(plug_pid, {:reply, h})
    { :next_state, :pause, %{sd | msgs: t}, @reconnect_timeout }
  end

  def pause({:connect, plug_pid}, sd) do
    { :next_state, :connect, %{sd | plug_pid: plug_pid}, @heartbeat_timeout }
  end

  def pause({:send_msg, data}, sd) do
    { :next_state, :pause, %{sd | msgs: sd.msgs ++ [data]}, @reconnect_timeout }
  end

  def pause(:timeout, sd) do
    { :stop, :normal, sd }
  end


  def connect({:send_msg, msg}, sd) do
    send(sd.plug_pid, {:reply, msg})
    { :next_state, :pause, %{sd | plug_pid: nil}, @reconnect_timeout }
  end

  def connect(:timeout, sd) do
    send(sd.plug_pid, {:reply, :pong})
    { :next_state, :pause, %{sd | plug_pid: nil}, @reconnect_timeout }
  end


  def handle_event(:server_close, _sn, sd) do
    { :stop, :normal, sd }
  end

  def handle_event(:client_close, _sn, sd) do
    { :stop, :normal, sd }
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

  def terminate(:normal, _sn, sd) do
    :ets.delete(:eio_polling, sd.sid)
    sd.mod.close
  end
end
