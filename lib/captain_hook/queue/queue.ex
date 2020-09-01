defmodule CaptainHook.Queue do
  use Queuetopia,
    repo: Application.fetch_env!(:captain_hook, :repo),
    performer: CaptainHook.Performer
end
