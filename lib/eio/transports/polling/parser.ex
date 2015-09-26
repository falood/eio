alias Eio.Transports.Polling, as: T

defmodule T.Parser do
  def encode(:close),          do: "1:1"
  def encode(:pong),           do: "1:3"
  def encode({:pong, msg}),    do: "#{byte_size(msg) + 1}:3#{msg}"
  def encode({:connect, msg}), do: "#{byte_size(msg) + 1}:0#{msg}"
  def encode({:message, msg}), do: "#{byte_size(msg) + 1}:4#{msg}"

  def encode(l) when is_list(l) do
    l |> Enum.map(&encode/1) |> Enum.join
  end

  def decode(s) do
    s |> Eio.Parser.payload([]) |> Enum.map &Eio.Parser.packet/1
  end
end
