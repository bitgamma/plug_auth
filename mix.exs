defmodule PlugAuth.Mixfile do
  use Mix.Project

  def project do
    [
      app: :plug_auth,
      version: "0.0.1",
      elixir: "~> 1.0",
      deps: deps,
      package: package,
      description: description,
      docs: [readme: "README.md", main: "README"]]
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
      {:plug, "~> 0.9.0"},
      {:earmark, "~> 0.1", only: :docs},
      {:ex_doc, "~> 0.6", only: :docs},
    ]
  end

  defp description do
    "A collection of authentication-related plugs"
  end

  defp package do
    [
      contributors: ["Michele Balistreri"],
      licenses: ["ISC"],
      links: %{"GitHub" => "https://github.com/briksoftware/plug_auth"}
    ]
  end
end
