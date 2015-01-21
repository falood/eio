defmodule EIO.Callback do
  def new(pid),             do: new(pid, :polling)
  def new(pid, :polling),   do: EIO.Callback.Polling.new(pid)
  def new(pid, :websocket), do: EIO.Callback.WebSocket.new(pid)

  defmodule Polling do
    defstruct pid: nil

    def new(pid) do
      {__MODULE__, %__MODULE__{pid: pid}}
    end

    def close({__MODULE__, %__MODULE__{pid: pid}}) do
      EIO.Conn.close(pid, :server)
    end

    def send(msg, {__MODULE__, %__MODULE__{pid: pid}}) do
      EIO.reply(pid, {:message, msg})
    end
  end

  defmodule WebSocket do
    defstruct pid: nil

    def new(pid) do
      {__MODULE__, %__MODULE__{pid: pid}}
    end

    def close({__MODULE__, %__MODULE__{pid: pid}}) do
      EIO.Conn.close(pid, :server)
    end

    def send(msg, {__MODULE__, %__MODULE__{pid: pid}}) do
      EIO.reply(pid, {:message, msg})
    end
  end
end
