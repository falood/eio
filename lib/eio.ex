defmodule EIO do
  def start(_, _) do
    :ets.new(:eio_polling, [:set, :named_table, :public])
    EIO.Supervisor.start_link
  end
end
