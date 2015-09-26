defmodule Eio.Transports.Polling do
  def start_worker(sid, router) do
    Eio.Transports.Polling.Supervisor.start_child({sid, router})
  end

  def close(pid, :client) do
    :gen_fsm.send_all_state_event(pid, {:close, :client})
  end

  def close(pid, :server) do
    :gen_fsm.send_all_state_event(pid, {:close, :server})
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
end
