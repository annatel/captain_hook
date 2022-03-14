import Config

if(Mix.env() == :test) do
  config :logger, level: System.get_env("EX_LOG_LEVEL", "warn") |> String.to_atom()

  config :captain_hook, ecto_repos: [CaptainHook.TestRepo]

  config :captain_hook, CaptainHook.TestRepo,
    url: System.get_env("DATABASE_TEST_URL"),
    show_sensitive_data_on_connection_error: true,
    pool: Ecto.Adapters.SQL.Sandbox

  config :captain_hook,
    repo: CaptainHook.TestRepo,
    notification_pattern_separator: ".",
    notification_pattern_wildcard: "+",
    notification_pattern_match_all_wildcard: "*",
    owner_id_field: [migration: {:owner_id, :binary_id}, schema: {:owner_id, :binary_id, []}]

  config :captain_hook, CaptainHook.Queuetopia, disable?: true

  config :padlock,
    repo: CaptainHook.TestRepo
end
