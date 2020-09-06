defmodule CaptainHook.Queue do
  use Queuetopia,
    repo: Application.get_env(:captain_hook, :repo),
    performer: CaptainHook.Queue.JobPerformer
end
