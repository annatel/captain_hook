defmodule CaptainHook.Migrations.V3 do
  @moduledoc false

  use Ecto.Migration

  def up do
    rename_sequences_to_old_sequences()
    create_sequences_table()

    alter_table_webhook_endpoints_rename_webhook_to_owner_id()
    alter_table_webhook_endpoints_rename_allow_insecure_to_is_insecure_allowed()
    alter_table_webhook_endpoints_add_is_enabled()
    alter_table_webhook_endpoints_add_object()
    alter_table_webhook_endpoints_add_api_version()
    alter_table_webhook_endpoints_rename_started_at_to_created_at()
    alter_table_webhook_endpoints_rename_ended_at_to_deleted_at()

    alter_table_webhook_notifications_remove_webhook()
    alter_table_webhook_notifications_remove_livemode()

    alter_table_webhook_notifications_add_webhook_endpoint_id()
    alter_table_webhook_notifications_add_succeeded_at()
    alter_table_webhook_notifications_add_idempotency_key()
    alter_table_webhook_notifications_add_attempt()
    alter_table_webhook_notifications_next_retry_at()
    alter_table_webhook_notifications_add_updated_at()
    alter_table_webhook_notifications_rename_resource_type_to_resource_object()
    alter_table_webhook_notifications_add_object()

    alter_table_webhook_conversations_remove_webhook_endpoint_id()
    alter_table_webhook_conversations_add_object()
  end

  def down do
    drop_sequences_table()
    rename_old_sequences_to_sequences_table()

    alter_table_webhook_endpoints_rename_is_insecure_allowed_to_allow_insecure()
    alter_table_webhook_endpoints_rename_subscriber_to_webhook()
    alter_table_webhook_endpoints_remove_is_enabled()
    alter_table_webhook_endpoints_remove_object()
    alter_table_webhook_endpoints_remove_api_version()
    alter_table_webhook_endpoints_rename_created_at_to_started_at()
    alter_table_webhook_endpoints_rename_deleted_at_to_ended_at()

    alter_table_webhook_notifications_remove_webhook_endpoint()
    alter_table_webhook_notifications_add_webhook()
    alter_table_webhook_notifications_add_livemode()
    alter_table_webhook_notifications_remove_succeeded_at()
    alter_table_webhook_notifications_remove_updated_at()
    alter_table_webhook_notifications_remove_idempotency_key()
    alter_table_webhook_notifications_remove_attempt()
    alter_table_webhook_notifications_remove_next_retry_at()
    alter_table_webhook_notifications_rename_resource_object_to_resource_type()
    alter_table_webhook_notifications_remove_object()

    alter_table_webhook_conversations_add_webhook_endpoint_id()
    alter_table_webhook_conversations_remove_object()
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

  defp alter_table_webhook_endpoints_rename_webhook_to_owner_id() do
    rename(table(:captain_hook_webhook_endpoints), :webhook,
      to: elem(CaptainHook.owner_id_field(:migration), 0)
    )

    alter table(:captain_hook_webhook_endpoints) do
      modify(
        elem(CaptainHook.owner_id_field(:migration), 0),
        elem(CaptainHook.owner_id_field(:migration), 1),
        null: false
      )
    end
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

  defp alter_table_webhook_endpoints_add_object() do
    alter table(:captain_hook_webhook_endpoints) do
      add(:object, :string, default: "webhook_endpoint")
    end
  end

  defp alter_table_webhook_endpoints_add_api_version() do
    execute(
      "ALTER TABLE captain_hook_webhook_endpoints ADD COLUMN api_version VARCHAR(255) NOT NULL AFTER id"
    )

    execute(
      "ALTER TABLE captain_hook_webhook_endpoints ADD INDEX captain_hook_webhook_endpoints_api_version_index (api_version);"
    )
  end

  defp alter_table_webhook_endpoints_rename_started_at_to_created_at() do
    execute(
      "ALTER TABLE captain_hook_webhook_endpoints CHANGE started_at created_at DATETIME NOT NULL;"
    )

    execute(
      "ALTER TABLE captain_hook_webhook_endpoints DROP INDEX captain_hook_webhook_endpoints_started_at_index;"
    )

    execute(
      "ALTER TABLE captain_hook_webhook_endpoints ADD INDEX captain_hook_webhook_endpoints_created_at_index (created_at);"
    )
  end

  defp alter_table_webhook_endpoints_rename_ended_at_to_deleted_at() do
    execute(
      "ALTER TABLE captain_hook_webhook_endpoints CHANGE ended_at deleted_at DATETIME NULL AFTER is_insecure_allowed;"
    )

    execute(
      "ALTER TABLE captain_hook_webhook_endpoints DROP INDEX captain_hook_webhook_endpoints_ended_at_index;"
    )

    execute(
      "ALTER TABLE captain_hook_webhook_endpoints ADD INDEX captain_hook_webhook_endpoints_deleted_at_index (deleted_at);"
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

  defp alter_table_webhook_notifications_rename_resource_type_to_resource_object() do
    execute(
      "ALTER TABLE captain_hook_webhook_notifications CHANGE resource_type resource_object VARCHAR(255) NULL;"
    )
  end

  defp alter_table_webhook_notifications_add_object() do
    alter table(:captain_hook_webhook_notifications) do
      add(:object, :string, default: "webhook_notification")
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

  defp alter_table_webhook_conversations_remove_webhook_endpoint_id() do
    execute("SET FOREIGN_KEY_CHECKS=0;")

    execute(
      "ALTER TABLE captain_hook_webhook_conversations DROP FOREIGN KEY captain_hook_webhook_conversations_webhook_endpoint_id_fkey;"
    )

    alter table(:captain_hook_webhook_conversations) do
      remove(:webhook_endpoint_id)
    end

    execute("SET FOREIGN_KEY_CHECKS=1;")
  end

  defp alter_table_webhook_conversations_add_object() do
    alter table(:captain_hook_webhook_conversations) do
      add(:object, :string, default: "webhook_conversation")
    end
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

  defp alter_table_webhook_endpoints_rename_subscriber_to_webhook() do
    rename(
      table(:captain_hook_webhook_endpoints),
      elem(CaptainHook.owner_id_field(:migration), 0),
      to: :webhook
    )

    alter table(:captain_hook_webhook_endpoints) do
      modify(:webhook, :string, null: false)
    end

    execute(
      "ALTER TABLE captain_hook_webhook_endpoints CHANGE subscriber webhook VARCHAR(255) NOT NULL;"
    )
  end

  defp alter_table_webhook_endpoints_remove_is_enabled() do
    alter table(:captain_hook_webhook_endpoints) do
      remove(:is_enabled)
    end
  end

  defp alter_table_webhook_endpoints_remove_object() do
    alter table(:captain_hook_webhook_endpoints) do
      remove(:object)
    end
  end

  defp alter_table_webhook_endpoints_remove_api_version() do
    alter table(:captain_hook_webhook_endpoints) do
      remove(:api_version)
    end
  end

  defp alter_table_webhook_endpoints_rename_created_at_to_started_at() do
    execute(
      "ALTER TABLE captain_hook_webhook_endpoints CHANGE created_at started_at DATETIME NULL;"
    )

    execute(
      "ALTER TABLE captain_hook_webhook_endpoints DROP INDEX captain_hook_webhook_endpoints_created_at_index;"
    )

    execute(
      "ALTER TABLE captain_hook_webhook_endpoints ADD INDEX captain_hook_webhook_endpoints_started_at_index (started_at);"
    )
  end

  defp alter_table_webhook_endpoints_rename_deleted_at_to_ended_at() do
    execute(
      "ALTER TABLE captain_hook_webhook_endpoints CHANGE deleted_at ended_at DATETIME NULL;"
    )

    execute(
      "ALTER TABLE captain_hook_webhook_endpoints DROP INDEX captain_hook_webhook_endpoints_deleted_at_index;"
    )

    execute(
      "ALTER TABLE captain_hook_webhook_endpoints ADD INDEX captain_hook_webhook_endpoints_ended_at_index (ended_at);"
    )
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

  defp alter_table_webhook_notifications_remove_object() do
    alter table(:captain_hook_webhook_notifications) do
      remove(:object)
    end
  end

  defp alter_table_webhook_notifications_rename_resource_object_to_resource_type() do
    execute(
      "ALTER TABLE captain_hook_webhook_notifications CHANGE resource_object resource_type VARCHAR(255) NULL;"
    )
  end

  defp alter_table_webhook_notifications_remove_updated_at() do
    alter table(:captain_hook_webhook_notifications) do
      remove(:updated_at)
    end
  end

  defp alter_table_webhook_conversations_remove_object() do
    alter table(:captain_hook_webhook_conversations) do
      remove(:object)
    end
  end
end
