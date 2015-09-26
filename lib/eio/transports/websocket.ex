defmodule Eio.Transports.WebSocket do
  def close(pid, :server) do
    send(pid, {:close, :server})
  end

  def reply(pid, msg) do
    send(pid, {:reply, msg})
  end
end
