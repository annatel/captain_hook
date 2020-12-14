defmodule CaptainHook.Queue do
  use Queuetopia,
    otp_app: :captain_hook,
    repo: Application.get_env(:captain_hook, :repo),
    performer: CaptainHook.Queue.JobPerformer
end
