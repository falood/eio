defmodule EIO.Session do
  use Bitwise
  defstruct sid: nil, conn_pid: nil, callback: nil

  def new do
    <<a::size(32), b::size(16), c::size(16), d::size(16), e::size(48)>>
      = :crypto.strong_rand_bytes(16)
    args = [a, b, c |> band(0x0fff), d |> band(0x3fff) |> bor(0x8000), e]
    :io_lib.format("~8.16.0B~4.16.0B4~3.16.0B~4.16.0B~12.16.0B", args)
    |> List.flatten |> to_string |> Base.encode64 |> String.slice(0, 24)
  end

  def get(nil), do: nil
  def get(sid) do
    case :ets.lookup(:eio_polling, sid) do
      [{^sid, session}] -> session
      _                 -> raise "unknow sid"
    end
  end

  def delete(sid) do
    :ets.delete(:eio_polling, sd.sid)
  end
end
