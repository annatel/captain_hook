defmodule CaptainHook.Queuetopia do
  @moduledoc false

  use Queuetopia,
    otp_app: :captain_hook,
    repo: Application.get_env(:captain_hook, :repo),
    performer: CaptainHook.Queuetopia.Performer
end
