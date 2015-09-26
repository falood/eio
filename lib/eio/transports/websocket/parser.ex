alias Eio.Transports.WebSocket, as: T

defmodule T.Parser do
  def encode(:pong),           do: "3"
  def encode({:pong, rest}),   do: "3#{rest}"
  def encode({:connect, msg}), do: "0#{msg}"
  def encode({:message, msg}), do: "4#{msg}"

  def decode(s) do
    s |> Eio.Parser.packet
  end
end
