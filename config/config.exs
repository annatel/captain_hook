import Config

if(Mix.env() == :test) do
  config :logger, level: System.get_env("EX_LOG_LEVEL", "warn") |> String.to_atom()

  config :captain_hook, ecto_repos: [CaptainHook.TestRepo]

  config :captain_hook, CaptainHook.TestRepo,
    url: System.get_env("CAPTAIN_HOOK__DATABASE_TEST_URL"),
    show_sensitive_data_on_connection_error: true,
    pool: Ecto.Adapters.SQL.Sandbox

  config :captain_hook,
    repo: CaptainHook.TestRepo

  config :captain_hook,
    default_wildcard_char: "*",
    default_separator: "."

  config :captain_hook, CaptainHook.Queuetopia, disable?: true
end
