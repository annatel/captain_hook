defmodule CaptainHook.MixProject do
  use Mix.Project

  @source_url "https://github.com/annatel/captain_hook"
  @version "0.7.0"

  def project do
    [
      app: :captain_hook,
      version: @version,
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs(),
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
      {:bypass, "~> 1.0", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:myxql, "~> 0.4.0"},
      {:ecto_sql, "~> 3.5"},
      {:antl_utils_elixir, "~> 0.2.0", override: true},
      {:antl_utils_ecto, "~> 0.7.0"},
      {:queuetopia, "~> 0.6.3"},
      {:finch, "~> 0.5"},
      {:recase, "~> 0.7"},
      {:shortcode, "~> 0.5.0"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      test: ["ecto.setup", "test"],
      "ecto.setup": [
        "ecto.create --quiet -r CaptainHook.TestRepo",
        "ecto.migrate -r CaptainHook.TestRepo"
      ],
      "ecto.reset": ["ecto.drop -r CaptainHook.TestRepo", "ecto.setup"]
    ]
  end

  defp description() do
    "Ordered webhook notifications"
  end

  defp package() do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_url: @source_url,
      extras: [
        "README.md"
      ]
    ]
  end
end
