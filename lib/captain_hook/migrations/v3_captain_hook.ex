defmodule CaptainHook.Migrations.V3.CaptainHook do
  @moduledoc false

  use Ecto.Migration

  def up do
    rename_webhook_sequences_to_old_webhook_sequences()
    create_webhook_sequences_table()
  end

  def down do
    drop_sequences_table()
    rename_old_sequences_to_sequences()
  end

  defp rename_webhook_sequences_to_old_webhook_sequences() do
    rename(table(:captain_hook_sequences),
      to: table(:captain_hook_old_sequences)
    )

    execute("SET FOREIGN_KEY_CHECKS=0;")

    [
      %{
        column: "webhook_conversations",
        old_index: "captain_hook_sequences_webhook_conversations_index",
        new_index: "captain_hook_old_sequences_webhook_conversations_index"
      }
    ]
    |> Enum.each(fn %{column: column, old_index: old_index, new_index: new_index} ->
      execute("ALTER TABLE captain_hook_old_sequences DROP INDEX #{old_index};")

      execute("ALTER TABLE captain_hook_old_sequences ADD INDEX #{new_index} (#{column});")
    end)

    execute("SET FOREIGN_KEY_CHECKS=1;")
  end

  defp create_webhook_sequences_table do
    create table(:captain_hook_sequences, primary: false) do
      add(:livemode, :boolean, null: false)
      add(:name, :string, null: false)
      add(:value, :bigint, null: false, default: 0)
    end

    create(unique_index(:captain_hook_sequences, [:name, :livemode]))

    execute("""
    DROP FUNCTION IF EXISTS captain_hook_nextval_gapless_sequence;
    """)

    execute("""
    CREATE FUNCTION captain_hook_nextval_gapless_sequence(in_sequence_name CHAR(255), in_livemode BOOLEAN)
    RETURNS INTEGER DETERMINISTIC
    begin
      declare next_value INTEGER;
      update captain_hook_sequences set value = LAST_INSERT_ID(value+1) where name = in_sequence_name and livemode = in_livemode;
      select LAST_INSERT_ID() into next_value;
      RETURN next_value;
    end;
    """)
  end

  defp drop_sequences_table do
    drop(table(:captain_hook_sequences))
  end

  defp rename_old_sequences_to_sequences() do
    rename(table(:old_webhook_conversations), to: table(:webhook_conversations))
  end
end
