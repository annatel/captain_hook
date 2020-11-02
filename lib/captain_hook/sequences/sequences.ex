defmodule CaptainHook.Sequences do
  @moduledoc false

  @spec next(:webhook_conversations) :: integer
  def next(table_name) when table_name in [:webhook_conversations] do
    Ecto.Adapters.SQL.query!(
      CaptainHook.repo(),
      "UPDATE `captain_hook_sequences` SET #{table_name} = LAST_INSERT_ID(#{table_name}+1)"
    )

    %{rows: [[last_insert_id]]} = CaptainHook.repo().query!("SELECT LAST_INSERT_ID()")

    last_insert_id
  end
end
