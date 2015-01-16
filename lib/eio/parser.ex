defmodule EIO.Parser do
  def encode(:pong),           do: "1:3"
  def encode({:connect, msg}), do: "#{byte_size(msg) + 1}:0#{msg}"
  def encode({:message, msg}), do: "#{byte_size(msg) + 1}:4#{msg}"

  def decode(s) do
    s |> payload([]) |> Enum.map &packet/1
  end

  defp payload("", result), do: result |> Enum.reverse
  defp payload(s, result) do
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

  defp packet(<<type::binary-size(1), rest::binary>>) do
    { @types[type], rest }
  end
end
