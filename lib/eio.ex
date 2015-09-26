defmodule Eio do
  def start(_, _) do
    Eio.Session.start
    Eio.Supervisor.start_link
  end
end
