defmodule CaptainHook.Migrations.V3.CaptainHook do
  @moduledoc false

  use Ecto.Migration

  def up do
    alter_table_webhook_endpoints_add_object_column()
    alter_table_webhook_endpoints_add_api_version_column()
    alter_table_webhook_endpoints_add_status_column()

    rename_webhook_sequences_to_old_webhook_sequences()
    create_webhook_sequences_table()

    alter_table_webhook_conversations_add_object_column()
    alter_table_webhook_notifications_add_object_column()
    alter_table_webhook_endpoint_secrets_add_object_column()
  end

  def down do
    alter_table_webhook_endpoints_remove_object_column()
    alter_table_webhook_endpoints_remove_api_version_column()
    alter_table_webhook_endpoints_remove_status_column()

    drop_sequences_table()
    rename_old_sequences_to_sequences()

    alter_table_webhook_conversations_remove_object_column()
    alter_table_webhook_notifications_remove_object_column()
    alter_table_webhook_endpoint_secrets_remove_object_column()
  end

  defp alter_table_webhook_endpoints_add_object_column() do
    execute(
      "ALTER TABLE captain_hook_webhook_endpoints ADD COLUMN object VARCHAR(255) NOT NULL DEFAULT 'webhook_endpoint' AFTER updated_at;"
    )
  end

  defp alter_table_webhook_endpoints_remove_object_column() do
    alter table(:captain_hook_webhook_endpoints) do
      remove(:object)
    end
  end

  defp alter_table_webhook_endpoints_add_api_version_column() do
    execute(
      "ALTER TABLE captain_hook_webhook_endpoints ADD COLUMN api_version VARCHAR(255) NULL AFTER ended_at;"
    )
  end

  defp alter_table_webhook_endpoints_remove_api_version_column() do
    alter table(:captain_hook_webhook_endpoints) do
      remove(:api_version)
    end
  end

  defp alter_table_webhook_endpoints_add_status_column() do
    execute(
      "ALTER TABLE captain_hook_webhook_endpoints ADD COLUMN status VARCHAR(255) NOT NULL AFTER allow_insecure;"
    )
  end

  defp alter_table_webhook_endpoints_remove_status_column() do
    alter table(:captain_hook_webhook_endpoints) do
      remove(:status)
    end
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

    case repo().__adapter__() do
      Ecto.Adapters.Postgres ->
        execute("""
        create or replace function nextval_gapless_sequence(in_sequence_name text, in_livemode bool)
        returns bigint
        language plpgsql
        as
        $$
        declare
          next_value bigint := 1;
        begin
          update sequences
          set value = value + 1
          where name = in_sequence_name and livemode = in_livemode
          returning value into next_value;

          return next_value;
        end;
        """)

      Ecto.Adapters.MyXQL ->
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
  end

  defp drop_sequences_table do
    drop(table(:captain_hook_sequences))
  end

  defp rename_old_sequences_to_sequences() do
    rename(table(:old_webhook_conversations), to: table(:webhook_conversations))
  end

  defp alter_table_webhook_endpoint_secrets_add_object_column() do
    execute(
      "ALTER TABLE captain_hook_webhook_endpoint_secrets ADD COLUMN object VARCHAR(255) NOT NULL DEFAULT 'webhook_endpoint_secret' AFTER updated_at;"
    )
  end

  defp alter_table_webhook_endpoint_secrets_remove_object_column() do
    alter table(:captain_hook_webhook_endpoint_secrets) do
      remove(:object)
    end
  end

  defp alter_table_webhook_conversations_add_object_column() do
    execute(
      "ALTER TABLE captain_hook_webhook_conversations ADD COLUMN object VARCHAR(255) NOT NULL DEFAULT 'webhook_conversation' AFTER updated_at;"
    )
  end

  defp alter_table_webhook_conversations_remove_object_column() do
    alter table(:captain_hook_webhook_conversations) do
      remove(:object)
    end
  end

  defp alter_table_webhook_notifications_add_object_column() do
    execute(
      "ALTER TABLE captain_hook_webhook_notifications ADD COLUMN object VARCHAR(255) NOT NULL DEFAULT 'webhook_notification' AFTER updated_at;"
    )
  end

  defp alter_table_webhook_notifications_remove_object_column() do
    alter table(:captain_hook_webhook_notifications) do
      remove(:object)
    end
  end
end
