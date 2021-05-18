defmodule CaptainHook.Migrations.V3 do
  @moduledoc false

  use Ecto.Migration

  def up do
    rename_sequences_to_old_sequences()
    create_sequences_table()

    alter_table_webhook_endpoints_rename_webhook_to_topic()
    alter_table_webhook_endpoints_rename_allow_insecure_to_is_insecure_allowed()
    alter_table_webhook_endpoints_add_is_enabled()

    alter_table_webhook_notifications_remove_webhook()
    alter_table_webhook_notifications_remove_livemode()

    alter_table_webhook_notifications_add_webhook_endpoint_id()
    alter_table_webhook_notifications_add_succeeded_at()
    alter_table_webhook_notifications_add_idempotency_key()
    alter_table_webhook_notifications_add_attempt()
    alter_table_webhook_notifications_next_retry_at()
    alter_table_webhook_notifications_add_updated_at()

    alter_table_webhook_notifications_remove_webhook_endpoint_id()
  end

  def down do
    drop_sequences_table()
    rename_old_sequences_to_sequences_table()

    alter_table_webhook_endpoints_rename_is_insecure_allowed_to_allow_insecure()
    alter_table_webhook_endpoints_rename_topic_to_webhook()
    alter_table_webhook_endpoints_remove_is_enabled()

    alter_table_webhook_notifications_remove_webhook_endpoint()
    alter_table_webhook_notifications_add_webhook()
    alter_table_webhook_notifications_add_livemode()
    alter_table_webhook_notifications_remove_succeeded_at()
    alter_table_webhook_notifications_remove_updated_at()
    alter_table_webhook_notifications_remove_idempotency_key()
    alter_table_webhook_notifications_remove_attempt()
    alter_table_webhook_notifications_remove_next_retry_at()

    alter_table_webhook_conversations_add_webhook_endpoint_id()
  end

  defp rename_sequences_to_old_sequences() do
    execute(
      "ALTER TABLE captain_hook_sequences DROP INDEX captain_hook_sequences_webhook_conversations_index;"
    )

    rename(table(:captain_hook_sequences), to: table(:captain_hook_old_sequences))
  end

  defp create_sequences_table() do
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
      SELECT 'webhook_notifications', captain_hook_old_sequences.webhook_notifications FROM captain_hook_old_sequences LIMIT 1"
    )

    execute(
      "INSERT INTO captain_hook_sequences(name, value)
      SELECT 'webhook_conversations', captain_hook_old_sequences.webhook_conversations FROM captain_hook_old_sequences LIMIT 1"
    )
  end

  defp alter_table_webhook_endpoints_rename_webhook_to_topic() do
    execute(
      "ALTER TABLE captain_hook_webhook_endpoints CHANGE webhook topic VARCHAR(255) NOT NULL;"
    )
  end

  defp alter_table_webhook_endpoints_rename_allow_insecure_to_is_insecure_allowed() do
    execute(
      "ALTER TABLE captain_hook_webhook_endpoints CHANGE allow_insecure is_insecure_allowed BOOLEAN NOT NULL;"
    )
  end

  defp alter_table_webhook_endpoints_add_is_enabled() do
    execute(
      "ALTER TABLE captain_hook_webhook_endpoints ADD COLUMN is_enabled BOOLEAN NOT NULL AFTER headers"
    )

    execute(
      "ALTER TABLE captain_hook_webhook_endpoints ADD INDEX captain_hook_webhook_endpoints_is_enabled_index (is_enabled);"
    )
  end

  defp alter_table_webhook_notifications_remove_webhook() do
    execute(
      "ALTER TABLE captain_hook_webhook_notifications DROP INDEX captain_hook_webhook_notifications_webhook_index;"
    )

    alter table(:captain_hook_webhook_notifications) do
      remove(:webhook)
    end
  end

  defp alter_table_webhook_notifications_remove_livemode() do
    execute(
      "ALTER TABLE captain_hook_webhook_notifications DROP INDEX captain_hook_webhook_notifications_livemode_index;"
    )

    alter table(:captain_hook_webhook_notifications) do
      remove(:livemode)
    end
  end

  defp alter_table_webhook_notifications_add_webhook_endpoint_id() do
    execute(
      "ALTER TABLE captain_hook_webhook_notifications ADD COLUMN webhook_endpoint_id BINARY(16) NOT NULL AFTER id"
    )

    execute(
      "ALTER TABLE captain_hook_webhook_notifications ADD CONSTRAINT captain_hook_webhook_notifications_webhook_endpoint_id_fkey FOREIGN KEY (webhook_endpoint_id) REFERENCES captain_hook_webhook_endpoints(id);"
    )
  end

  defp alter_table_webhook_notifications_add_succeeded_at() do
    execute(
      "ALTER TABLE captain_hook_webhook_notifications ADD COLUMN succeeded_at DATETIME NULL AFTER sequence"
    )

    execute(
      "ALTER TABLE captain_hook_webhook_notifications ADD INDEX captain_hook_webhook_notifications_succeeded_at_index (succeeded_at);"
    )
  end

  defp alter_table_webhook_notifications_add_updated_at() do
    alter table(:captain_hook_webhook_notifications) do
      add(:updated_at, :utc_datetime, null: false)
    end
  end

  defp alter_table_webhook_notifications_add_idempotency_key do
    execute(
      "ALTER TABLE captain_hook_webhook_notifications ADD COLUMN idempotency_key VARCHAR(255) NULL AFTER data"
    )

    execute(
      "ALTER TABLE captain_hook_webhook_notifications ADD UNIQUE INDEX captain_hook_webhook_notifications_idempotency_key_index (idempotency_key);"
    )
  end

  defp alter_table_webhook_notifications_add_attempt do
    execute(
      "ALTER TABLE captain_hook_webhook_notifications ADD COLUMN attempt INTEGER NOT NULL AFTER webhook_endpoint_id"
    )
  end

  defp alter_table_webhook_notifications_next_retry_at do
    execute(
      "ALTER TABLE captain_hook_webhook_notifications ADD COLUMN next_retry_at DATETIME NULL AFTER idempotency_key"
    )
  end

  defp alter_table_webhook_notifications_remove_webhook_endpoint_id() do
    execute("SET FOREIGN_KEY_CHECKS=0;")

    execute(
      "ALTER TABLE captain_hook_webhook_conversations DROP FOREIGN KEY captain_hook_webhook_conversations_webhook_endpoint_id_fkey;"
    )

    alter table(:captain_hook_webhook_conversations) do
      remove(:webhook_endpoint_id)
    end

    execute("SET FOREIGN_KEY_CHECKS=1;")
  end

  defp drop_sequences_table() do
    drop(table(:captain_hook_sequences))
  end

  defp rename_old_sequences_to_sequences_table() do
    rename(table(:captain_hook_old_sequences), to: table(:captain_hook_sequences))
  end

  defp alter_table_webhook_endpoints_rename_is_insecure_allowed_to_allow_insecure() do
    execute(
      "ALTER TABLE captain_hook_webhook_endpoints CHANGE is_insecure_allowed allow_insecure BOOLEAN NOT NULL;"
    )
  end

  defp alter_table_webhook_endpoints_rename_topic_to_webhook() do
    execute(
      "ALTER TABLE captain_hook_webhook_endpoints CHANGE topic webhook VARCHAR(255) NOT NULL;"
    )
  end

  defp alter_table_webhook_endpoints_remove_is_enabled() do
    alter table(:captain_hook_webhook_endpoints) do
      remove(:is_enabled)
    end
  end

  defp alter_table_webhook_notifications_remove_webhook_endpoint() do
    execute("SET FOREIGN_KEY_CHECKS=0;")

    execute(
      "ALTER TABLE captain_hook_webhook_notifications DROP FOREIGN KEY captain_hook_webhook_notifications_webhook_endpoint_id_fkey;"
    )

    alter table(:captain_hook_webhook_notifications) do
      remove(:webhook_endpoint_id)
    end

    execute("SET FOREIGN_KEY_CHECKS=1;")
  end

  defp alter_table_webhook_notifications_add_webhook() do
    alter table(:captain_hook_webhook_notifications) do
      add(:webhook, :string)
    end
  end

  defp alter_table_webhook_notifications_add_livemode() do
    alter table(:captain_hook_webhook_notifications) do
      add(:livemode, :boolean, null: false)
    end
  end

  defp alter_table_webhook_conversations_add_webhook_endpoint_id() do
    execute(
      "ALTER TABLE captain_hook_webhook_conversations ADD COLUMN webhook_endpoint_id BINARY(16) NOT NULL AFTER id"
    )
  end

  defp alter_table_webhook_notifications_remove_succeeded_at() do
    alter table(:captain_hook_webhook_notifications) do
      remove(:succeeded_at)
    end
  end

  defp alter_table_webhook_notifications_remove_idempotency_key() do
    alter table(:captain_hook_webhook_notifications) do
      remove(:idempotency_key)
    end
  end

  defp alter_table_webhook_notifications_remove_attempt() do
    alter table(:captain_hook_webhook_notifications) do
      remove(:attempt)
    end
  end

  defp alter_table_webhook_notifications_remove_next_retry_at() do
    alter table(:captain_hook_webhook_notifications) do
      remove(:next_retry_at)
    end
  end

  defp alter_table_webhook_notifications_remove_updated_at() do
    alter table(:captain_hook_webhook_notifications) do
      remove(:updated_at)
    end
  end
end
