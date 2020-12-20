import Config

config :captain_hook, CaptainHook.Queue,
  poll_interval: 60 * 1_000,
  repoll_after_job_performed?: true

if(Mix.env() == :test) do
  config :logger, level: System.get_env("EX_LOG_LEVEL", "warn") |> String.to_atom()

  config :captain_hook, ecto_repos: [CaptainHook.TestRepo]

  config :captain_hook, CaptainHook.TestRepo,
    url: System.get_env("CAPTAIN_HOOK__DATABASE_TEST_URL"),
    show_sensitive_data_on_connection_error: true,
    pool: Ecto.Adapters.SQL.Sandbox

  config :captain_hook,
    repo: CaptainHook.TestRepo

  config :captain_hook, CaptainHook.Queue, disable?: true
end
