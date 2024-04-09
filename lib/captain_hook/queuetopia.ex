defmodule CaptainHook.Queuetopia do
  @moduledoc false

  use Queuetopia,
    otp_app: :captain_hook,
    repo: Application.compile_env(:captain_hook, :repo),
    performer: CaptainHook.Queuetopia.Performer
end
