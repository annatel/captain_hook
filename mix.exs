defmodule CaptainHook.MixProject do
  use Mix.Project

  def project do
    [
      app: :captain_hook,
      version: "0.7.0",
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
      {:ecto_sql, "~> 3.5"},
      {:antl_utils_elixir, "~> 0.2.0", override: true},
      {:antl_utils_ecto, "~> 0.4.0"},
      {:queuetopia, "~> 0.6.1"},
      {:httpoison, "~> 1.7"},
      {:recase, "~> 0.7"},
      {:shortcode, "~> 0.5.0"}
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
