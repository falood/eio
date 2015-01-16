defmodule EIO do
  def start(_, _) do
    :ets.new(:eio_polling, [:set, :named_table, :public])
    # Plug.Adapters.Cowboy.http EIO.Polling.Router, [port: 4000]
    EIO.Supervisor.start_link
  end
end
