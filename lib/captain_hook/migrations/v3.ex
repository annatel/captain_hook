defmodule CaptainHook.Migrations.V3 do
  @moduledoc false

  use Ecto.Migration

  def up do
    execute(
      "ALTER TABLE captain_hook_sequences DROP INDEX captain_hook_sequences_webhook_conversations_index;"
    )

    rename(table(:captain_hook_sequences), to: table(:old_captain_hook_sequences))

    create table(:captain_hook_sequences, primary: false) do
      add(:name, :string, null: false)
      add(:value, :bigint, null: false, default: 0)
    end

    create(unique_index(:captain_hook_sequences, [:name]))

    execute("""
    DROP FUNCTION IF EXISTS captain_hook_nextval_gapless_sequence;
    """)

    execute("""
    CREATE FUNCTION captain_hook_nextval_gapless_sequence(in_sequence_name CHAR(255))
    RETURNS INTEGER DETERMINISTIC
    BEGIN
      UPDATE captain_hook_sequences SET value = LAST_INSERT_ID(value+1) WHERE name = in_sequence_name;
      RETURN LAST_INSERT_ID();
    end;
    """)

    execute(
      "INSERT INTO captain_hook_sequences(name, value)
      SELECT 'webhook_notifications', old_captain_hook_sequences.webhook_notifications FROM old_captain_hook_sequences LIMIT 1"
    )

    execute(
      "INSERT INTO captain_hook_sequences(name, value)
      SELECT 'webhook_conversations', old_captain_hook_sequences.webhook_conversations FROM old_captain_hook_sequences LIMIT 1"
    )

    execute(
      "ALTER TABLE captain_hook_webhook_endpoints CHANGE is_insecure_allowed is_insecure_allowed BOOLEAN NOT NULL;"
    )
  end

  def down do
    drop(table(:captain_hook_sequences))
    rename(table(:old_captain_hook_sequences), to: table(:captain_hook_sequences))

    execute(
      "ALTER TABLE captain_hook_webhook_endpoints CHANGE is_insecure_allowed is_insecure_allowed BOOLEAN NOT NULL;"
    )
  end
end
