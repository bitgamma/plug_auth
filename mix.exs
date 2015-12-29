defmodule PlugAuth.Mixfile do
  use Mix.Project

  def project do
    [
      app: :plug_auth,
      version: "0.2.0",
      elixir: "~> 1.1",
      deps: deps,
      package: package,
      description: description,
    ]
  end

  def application do
    [
      applications: [:logger, :cowboy, :plug],
      mod: {PlugAuth, []}
    ]
  end

  defp deps do
    [
      {:cowboy, "~> 1.0.0"},
      {:plug, "~> 0.14 or ~> 1.0"},
      {:earmark, "~> 0.1", only: :dev},
      {:ex_doc, "~> 0.11", only: :dev},
    ]
  end

  defp description do
    "A collection of authentication-related plugs"
  end

  defp package do
    [
      contributors: ["Michele Balistreri"],
      licenses: ["ISC"],
      links: %{"GitHub" => "https://github.com/bitgamma/plug_auth"}
    ]
  end
end
