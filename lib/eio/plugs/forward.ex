defmodule EIO.Plugs.Forword do
  def init(opts) do
    opts |> Keyword.fetch! :to
  end

  def call(conn, to) do
    if ["engine.io"] == conn.path_info do
      to.call(conn, [])
    else
      conn
    end
  end
end
