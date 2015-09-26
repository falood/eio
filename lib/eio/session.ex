defmodule Eio.Session do
  defstruct sid: nil, worker_pid: nil, transport: nil

  def start do
    :ets.new(:eio_session, [:set, :named_table, :public])
  end

  def generate_id do
    Eio.UUID.generate
  end


  def save(%__MODULE__{sid: sid}=session) do
    :ets.insert(:eio_session, {sid, session})
  end


  def get(nil), do: nil
  def get(sid) do
    case :ets.lookup(:eio_session, sid) do
      [{^sid, session}] -> session
      []                -> raise "unknown sid"
    end
  end


  def delete(%__MODULE__{sid: sid}) do
    :ets.delete(:eio_session, sid)
  end

  def delete(sid) do
    :ets.delete(:eio_session, sid)
  end


  def send(%__MODULE__{worker_pid: pid, transport: transport}, msg) do
    transport.reply(pid, {:message, msg})
  end

  def close(%__MODULE__{worker_pid: pid, transport: transport}, from \\ :server) when from in [:server, :client] do
    transport.close(pid, from)
  end
end
