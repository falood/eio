defmodule EIO.Polling.Callback do
  defstruct pid: nil

  def new(pid) do
    {__MODULE__, %__MODULE__{pid: pid}}
  end

  def close({__MODULE__, %__MODULE__{pid: pid}}) do
    :gen_fsm.send_all_state_event(pid, :server_close)
  end

  def send(msg, {__MODULE__, %__MODULE__{pid: pid}}) do
    :gen_fsm.send_event(pid, {:send_msg, {:message, msg}})
  end
end
