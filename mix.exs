defmodule EngineIO.Mixfile do
  use Mix.Project

  def project do
    [ app: :engineio,
      version: "0.0.1",
      elixir: "~> 1.0",
      deps: deps,
    ]
  end

  def application do
    [ mod: { EngineIO, [] },
      applications: [:logger, :plug]
    ]
  end

  defp deps do
    [ { :cowboy, "~> 1.0.0" },
      { :plug,   "~> 0.9.0" },
    ]
  end
end
