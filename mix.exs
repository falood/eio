defmodule EIO.Mixfile do
  use Mix.Project

  def project do
    [ app: :eio,
      version: "0.0.2",
      elixir: "~> 1.0",
      deps: deps,
      description: "Elixir Server of engine.io",
      source_url: "https://github.com/elixir-cn/eio",
      package: package,
    ]
  end

  def application do
    [ mod: { EIO, [] },
      applications: [:logger, :plug]
    ]
  end

  defp deps do
    [ { :cowboy, "~> 1.0.0" },
      { :plug,   "~> 0.10.0" },
      { :poison, "~> 1.3.1" },
    ]
  end

  defp package do
    %{ licenses: ["BSD 3-Clause"],
       links: %{"Github" => "https://github.com/elixir-cn/eio"}
     }
  end
end
