defmodule CaptainHook.MixProject do
  use Mix.Project

  @source_url "https://github.com/annatel/captain_hook"
  @version "1.8.0"

  def project do
    [
      app: :captain_hook,
      version: @version,
      elixir: "~> 1.10",
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
      {:bypass, "~> 2.1.0", only: :test},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:myxql, "~> 0.4.0", only: [:dev, :test]},
      {:postgrex, ">= 0.0.0", only: [:dev, :test]},
      {:ecto_sql, "~> 3.5"},
      {:captain_hook_signature, "~> 0.4.0"},
      {:antl_utils_elixir, "~> 0.2.0"},
      {:antl_utils_ecto, "~> 1.1.2"},
      {:queuetopia,
       git: "https://github.com/annatel/queuetopia.git", branch: "support_postgresql"},
      {:finch, "~> 0.6.0"},
      {:plug_crypto, "~> 1.1"},
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
    "Ordered signed webhook notifications"
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
