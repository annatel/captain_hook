defmodule CaptainHook.Sequences do
  @moduledoc false

  @spec next_value!(binary) :: integer
  def next_value!(name) when name in [:webhook_notifications, :webhook_conversations] do
    %{rows: [[nextval]]} =
      CaptainHook.repo().query!("SELECT captain_hook_nextval_gapless_sequence(?);", [
        to_string(name)
      ])

    nextval
  end
end
