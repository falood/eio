defmodule Eio.UUID do
  def generate do
    bingenerate() |> encode
  end

  defp bingenerate do
    <<u0::48, _::4, u1::12, _::2, u2::62>> = :crypto.strong_rand_bytes(16)
    <<u0::48, 4::4, u1::12, 2::2, u2::62>>
  end

  defp encode(<<u0::32, u1::16, u2::16, u3::16, u4::48>>) do
    hex_pad(u0, 8) <> hex_pad(u1, 4) <> hex_pad(u2, 4) <> hex_pad(u3, 4) <> hex_pad(u4, 12)
  end

  defp hex_pad(hex, count) do
    hex = Integer.to_string(hex, 16)
    lower(hex, :binary.copy("0", count - byte_size(hex)))
  end

  defp lower(<<h, t::binary>>, acc) when h in ?A..?F,
    do: lower(t, acc <> <<h + 32>>)
  defp lower(<<h, t::binary>>, acc),
    do: lower(t, acc <> <<h>>)
  defp lower(<<>>, acc),
    do: acc
end
