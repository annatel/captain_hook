defmodule CaptainHook.MixProject do
  use Mix.Project

  def project do
    [
      app: :captain_hook,
      version: "0.6.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:mox, "~> 0.4", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:ex_machina, "~> 2.3", only: :test},
      {:myxql, "~> 0.4.0"},
      {:ecto_sql, "~> 3.0"},
      {:antl_utils_elixir, "~> 0.1.0"},
      {:antl_utils_ecto, git: "https://github.com/annatel/antl_utils_ecto", branch: "master"},
      {:queuetopia, "~> 0.6.0"},
      {:httpoison, "~> 1.7"},
      {:recase,
       git: "https://github.com/sobolevn/recase", ref: "1a1e0c9f3eec84d827b912906476f0a1144174fb"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  defp description() do
    "Ordered webhook notifications"
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/annatel/captain_hook"}
    ]
  end
end
