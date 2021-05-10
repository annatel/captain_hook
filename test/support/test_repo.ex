defmodule CaptainHook.TestRepo do
  use Ecto.Repo,
    otp_app: :captain_hook,
    adapter: Ecto.Adapters.Postgres
end
