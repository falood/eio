defmodule EIO.Parser do
  defmodule Polling do
    def encode(:pong),           do: "1:3"
    def encode({:pong, msg}),    do: "#{byte_size(msg) + 1}:3#{msg}"
    def encode({:connect, msg}), do: "#{byte_size(msg) + 1}:0#{msg}"
    def encode({:message, msg}), do: "#{byte_size(msg) + 1}:4#{msg}"

    def decode(s) do
      s |> EIO.Parser.payload([]) |> Enum.map &EIO.Parser.packet/1
    end
  end

  defmodule WebSocket do
    def encode(:pong),           do: "3"
    def encode({:pong, rest}),   do: "3#{rest}"
    def encode({:connect, msg}), do: "0#{msg}"
    def encode({:message, msg}), do: "4#{msg}"

    def decode(s) do
      s |> EIO.Parser.packet
    end
  end


  def payload("", result), do: result |> Enum.reverse
  def payload(s, result) do
    [len, rest] = s |> String.split(":", parts: 2)
    {packet, rest} = String.split_at(rest, String.to_integer(len))
    payload(rest, [packet | result])
  end

  @types %{
    "0" => :open,
    "1" => :close,
    "2" => :ping,
    "3" => :pong,
    "4" => :message,
    "5" => :upgrade,
    "6" => :noop,
  }

  def packet(<<type::binary-size(1), rest::binary>>) do
    { @types[type], rest }
  end
end
