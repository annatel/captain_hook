defmodule CaptainHook.Queue do
  @moduledoc false

  use Queuetopia,
    otp_app: :captain_hook,
    repo: Application.get_env(:captain_hook, :repo),
    performer: CaptainHook.Queue.JobPerformer
end
