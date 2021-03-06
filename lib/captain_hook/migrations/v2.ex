defmodule CaptainHook.Migrations.V2 do
  @moduledoc false

  use Ecto.Migration

  def up do
    alter_table_webhook_endpoints_add_livemode_column()
    alter_table_webhook_endpoints_remove_metada_column()

    create_sequences_table()
    create_webhook_notifications_table()
    rename_webhook_conversations_to_old_webhook_conversations()
    create_webhook_conversations_table()

    create_webhook_endpoint_secrets_table()
    create_webhook_endpoint_enabled_notification_types_table()
  end

  def down do
    alter_table_webhook_endpoints_remove_livemode_column()
    alter_table_webhook_endpoints_add_metada_column()

    drop_sequences_table()

    drop_webhook_conversations_table()
    drop_webhook_notifications_table()
    rename_old_webhook_conversations_to_webhook_conversations()

    drop_webhook_endpoint_secrets_table()
    drop_webhook_endpoint_enabled_notification_types_table()
  end

  defp alter_table_webhook_endpoints_add_livemode_column() do
    execute(
      "ALTER TABLE captain_hook_webhook_endpoints ADD COLUMN livemode TINYINT(1) NOT NULL AFTER ended_at;"
    )

    create(index(:captain_hook_webhook_endpoints, [:livemode]))

    # execute("UPDATE captain_hook_webhook_endpoints SET livemode = 1")
  end

  defp alter_table_webhook_endpoints_remove_metada_column() do
    alter table(:captain_hook_webhook_endpoints) do
      remove(:metadata)
    end
  end

  defp create_sequences_table do
    create table(:captain_hook_sequences) do
      add(:webhook_notifications, :integer, null: false)
      add(:webhook_conversations, :integer, null: false)

      timestamps()
    end

    create(index(:captain_hook_sequences, [:webhook_conversations]))

    utc_now = DateTime.utc_now() |> DateTime.to_naive()

    execute(
      "INSERT INTO captain_hook_sequences(`webhook_conversations`, `webhook_notifications`, `inserted_at`, `updated_at`) VALUE (0, 0, '#{utc_now}', '#{utc_now}');"
    )
  end

  defp create_webhook_notifications_table() do
    create table(:captain_hook_webhook_notifications, primary_key: false) do
      add(:id, :uuid, primary_key: true)

      add(:webhook, :string, null: false)
      add(:livemode, :boolean, null: false)

      add(:created_at, :utc_datetime, null: false)
      add(:data, :map, null: true)
      add(:resource_id, :string, null: true)
      add(:resource_type, :string, null: true)
      add(:sequence, :integer, null: false)
      add(:type, :string, null: false)

      timestamps(updated_at: false)
    end

    create(index(:captain_hook_webhook_notifications, [:webhook]))
    create(index(:captain_hook_webhook_notifications, [:livemode]))
    create(index(:captain_hook_webhook_notifications, [:created_at]))
    create(index(:captain_hook_webhook_notifications, [:resource_id]))

    create(
      index(:captain_hook_webhook_notifications, [:resource_type, :resource_id],
        name: "captain_hook_webhook_notifications_rt_ri_index"
      )
    )

    create(index(:captain_hook_webhook_notifications, [:sequence]))
    create(index(:captain_hook_webhook_notifications, [:type]))
  end

  defp rename_webhook_conversations_to_old_webhook_conversations() do
    rename(table(:captain_hook_webhook_conversations),
      to: table(:captain_hook_old_webhook_conversations)
    )

    execute("SET FOREIGN_KEY_CHECKS=0;")

    execute(
      "ALTER TABLE captain_hook_old_webhook_conversations DROP FOREIGN KEY captain_hook_webhook_conversations_webhook_endpoint_id_fkey;"
    )

    execute(
      "ALTER TABLE captain_hook_old_webhook_conversations ADD CONSTRAINT captain_hook_old_webhook_conversations_webhook_endpoint_id_fkey FOREIGN KEY (webhook_endpoint_id) REFERENCES webhook_endpoint(id);"
    )

    [
      %{
        column: "resource_id",
        old_index: "captain_hook_webhook_conversations_resource_id_index",
        new_index: "captain_hook_old_webhook_conversations_resource_id_index"
      },
      %{
        column: "resource_type, resource_id",
        old_index: "captain_hook_webhook_conversations_rt_ri_index",
        new_index: "captain_hook_old_webhook_conversations_rt_ri_index"
      },
      %{
        column: "request_id",
        old_index: "captain_hook_webhook_conversations_request_id_index",
        new_index: "captain_hook_old_webhook_conversations_request_id_index"
      },
      %{
        column: "status",
        old_index: "captain_hook_webhook_conversations_status_index",
        new_index: "captain_hook_old_webhook_conversations_status_index"
      },
      %{
        column: "inserted_at",
        old_index: "captain_hook_webhook_conversations_inserted_at_index",
        new_index: "captain_hook_old_webhook_conversations_inserted_at_index"
      }
    ]
    |> Enum.each(fn %{column: column, old_index: old_index, new_index: new_index} ->
      execute("ALTER TABLE captain_hook_old_webhook_conversations DROP INDEX #{old_index};")

      execute(
        "ALTER TABLE captain_hook_old_webhook_conversations ADD INDEX #{new_index} (#{column});"
      )
    end)

    execute("SET FOREIGN_KEY_CHECKS=1;")
  end

  defp create_webhook_conversations_table() do
    create table(:captain_hook_webhook_conversations, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(
        :webhook_endpoint_id,
        references(:captain_hook_webhook_endpoints, on_delete: :nothing, type: :binary_id),
        null: false
      )

      add(
        :webhook_notification_id,
        references(:captain_hook_webhook_notifications, on_delete: :nothing, type: :binary_id),
        null: false
      )

      add(:sequence, :integer, null: false)
      add(:requested_at, :utc_datetime, null: false)

      add(:request_url, :string, null: false)
      add(:request_headers, :map, null: true)
      add(:request_body, :text, null: true)

      add(:http_status, :integer, null: true)
      add(:response_body, :text, null: true)
      add(:client_error_message, :text, null: true)

      add(:status, :string, null: true)

      timestamps(updated_at: false)
    end

    create(index(:captain_hook_webhook_conversations, [:sequence]))
    create(index(:captain_hook_webhook_conversations, [:status]))
  end

  defp create_webhook_endpoint_secrets_table do
    create table(:captain_hook_webhook_endpoint_secrets) do
      add(
        :webhook_endpoint_id,
        references(:captain_hook_webhook_endpoints, on_delete: :delete_all, type: :binary_id),
        null: false
      )

      add(:started_at, :utc_datetime, null: false)
      add(:ended_at, :utc_datetime, null: true)

      add(:secret, :string, null: false)
      add(:is_main, :boolean, null: false)

      timestamps()
    end

    create(index(:captain_hook_webhook_endpoint_secrets, [:is_main]))
    create(index(:captain_hook_webhook_endpoint_secrets, [:started_at]))
    create(index(:captain_hook_webhook_endpoint_secrets, [:ended_at]))
  end

  defp create_webhook_endpoint_enabled_notification_types_table do
    create table(:captain_hook_webhook_endpoint_enabled_notification_types) do
      add(
        :webhook_endpoint_id,
        references(:captain_hook_webhook_endpoints,
          on_delete: :delete_all,
          type: :binary_id,
          name: "ch_we_enabled_notification_types_webhook_endpoint_id_fkey"
        ),
        null: false
      )

      add(:name, :string, null: false)

      timestamps()
    end

    create(
      index(:captain_hook_webhook_endpoint_enabled_notification_types, [:name],
        name: "ch_we_endpoint_enabled_notification_types_name_index"
      )
    )
  end

  defp alter_table_webhook_endpoints_remove_livemode_column() do
    alter table(:captain_hook_webhook_endpoints) do
      remove(:livemode)
    end
  end

  defp alter_table_webhook_endpoints_add_metada_column() do
    alter table(:captain_hook_webhook_endpoints) do
      add(:metadata, :map, null: true)
    end
  end

  defp drop_sequences_table do
    drop(table(:captain_hook_sequences))
  end

  defp drop_webhook_notifications_table do
    drop(table(:captain_hook_webhook_notifications))
  end

  defp drop_webhook_conversations_table() do
    execute("SET FOREIGN_KEY_CHECKS=0;")

    execute(
      "ALTER TABLE captain_hook_webhook_conversations DROP FOREIGN KEY captain_hook_webhook_conversations_webhook_notification_id_fkey;"
    )

    drop(table(:captain_hook_webhook_conversations))

    execute("SET FOREIGN_KEY_CHECKS=1;")
  end

  defp rename_old_webhook_conversations_to_webhook_conversations() do
    rename(table(:captain_hook_old_webhook_conversations),
      to: table(:captain_hook_webhook_conversations)
    )
  end

  defp drop_webhook_endpoint_secrets_table do
    drop(table(:captain_hook_webhook_endpoint_secrets))
  end

  defp drop_webhook_endpoint_enabled_notification_types_table do
    drop(table(:captain_hook_webhook_endpoint_enabled_notification_types))
  end
end
