defmodule Eio.Parser do
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
