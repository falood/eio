defmodule Eio.Mixfile do
  use Mix.Project

  def project do
    [ app: :eio,
      version: "0.1.0",
      elixir: "~> 1.0",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      description: "Elixir Server of engine.io",
      source_url: "https://github.com/falood/eio",
      package: package,
    ]
  end

  def application do
    [ mod: { Eio, [] },
      applications: [:logger, :plug]
    ]
  end

  defp deps do
    [ { :cowboy, "~> 1.0" },
      { :plug,   "~> 1.0" },
      { :poison, "~> 1.5" },
    ]
  end

  defp package do
    %{ licenses: ["BSD 3-Clause"],
       links: %{"Github" => "https://github.com/falood/eio"}
     }
  end
end
