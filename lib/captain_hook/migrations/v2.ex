defmodule CaptainHook.Migrations.V2 do
  @moduledoc false

  use Ecto.Migration

  def up do
    alter_table_webhook_endpoints_add_livemode_column()

    create_sequences_table()

    create_webhook_notifications_table()

    alter_table_webhook_conversations_add_sequence_column()
    alter_table_webhook_conversations_add_reference_to_webhook_notifications()
    alter_table_webhook_conversations_remove_columns_of_webhook_notifications()

    create_webhook_endpoint_secrets_table()
    create_webhook_endpoint_enabled_notification_types_table()
  end

  def down do
    alter_table_webhook_endpoints_remove_livemode_column()

    drop_sequences_table()

    drop_webhook_notifications_table()

    alter_table_webhook_conversations_remove_sequence_column()
    alter_table_webhook_conversations_remove_reference_to_webhook_notifications()
    alter_table_webhook_conversations_revert_remove_columns_of_webhook_notifications()

    drop_webhook_endpoint_secrets_table()
    drop_webhook_endpoint_enabled_notification_types_table()
  end

  defp alter_table_webhook_endpoints_add_livemode_column() do
    execute(
      "ALTER TABLE captain_hook_webhook_endpoints ADD COLUMN livemode TINYINT(1) NOT NULL AFTER ended_at;"
    )

    create(index(:captain_hook_webhook_endpoints, [:livemode]))

    execute("UPDATE captain_hook_webhook_endpoints SET livemode = 1")
  end

  defp create_sequences_table do
    create table(:captain_hook_sequences) do
      add(:webhook_notifications, :integer, null: false)
      add(:webhook_conversations, :integer, null: false)

      timestamps()
    end

    create(index(:captain_hook_sequences, [:webhook_conversations]))
    flush()
    seed_captain_hook_sequence()
  end

  defp seed_captain_hook_sequence() do
    utc_now = DateTime.utc_now() |> DateTime.to_naive()

    %{rows: [[count_of_webhook_conversations]]} =
      repo().query!("SELECT COUNT(*) FROM captain_hook_webhook_conversations")

    start_sequence_value =
      if count_of_webhook_conversations > 0, do: count_of_webhook_conversations - 1, else: 0

    execute(
      "INSERT into captain_hook_sequences(`webhook_conversations`, `inserted_at`, `updated_at`) VALUE (#{
        start_sequence_value
      }, '#{utc_now}', '#{utc_now}');"
    )

    execute(
      "INSERT into captain_hook_sequences(`webhook_notifications`, `inserted_at`, `updated_at`) VALUE (1, '#{
        utc_now
      }', '#{utc_now}');"
    )
  end

  defp create_webhook_notifications_table() do
    create table(:captain_hook_webhook_notifications, primary_key: false) do
      add(:id, :uuid, primary_key: true)

      add(
        :webhook_endpoint_id,
        references(:captain_hook_webhook_endpoints, on_delete: :delete_all, type: :binary_id),
        null: false
      )

      add(:created_at, :utc_datetime, null: false)
      add(:data, :map, null: true)
      add(:resource_id, :string, null: true)
      add(:resource_type, :string, null: true)
      add(:sequence, :integer, null: false)
      add(:type, :string, null: false)

      timestamps()
    end

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

  defp alter_table_webhook_conversations_add_sequence_column() do
    execute(
      "ALTER TABLE captain_hook_webhook_conversations ADD COLUMN sequence BIGINT unsigned NOT NULL AFTER id;"
    )

    create(index(:captain_hook_webhook_conversations, [:sequence]))
    flush()
    seed_webhook_conversation_sequence()
  end

  defp seed_webhook_conversation_sequence() do
    %{rows: ids} =
      repo().query!("SELECT id FROM captain_hook_webhook_conversations ORDER BY inserted_at ASC")

    ids
    |> Enum.with_index()
    |> Enum.each(fn {[id], sequence} ->
      id = Ecto.UUID.cast!(id) |> String.replace("-", "") |> String.upcase()

      execute(
        "UPDATE captain_hook_webhook_conversations SET `sequence` = #{sequence} where `id` = UNHEX('#{
          id
        }')"
      )
    end)
  end

  defp alter_table_webhook_conversations_add_reference_to_webhook_notifications() do
    execute(
      "ALTER TABLE captain_hook_webhook_conversations ADD COLUMN webhook_notification_id BINARY(16) NOT NULL AFTER id;"
    )

    execute(
      "ALTER TABLE captain_hook_webhook_conversations ADD CONSTRAINT fk_webhook_notification_id FOREIGN KEY (webhook_notification_id) REFERENCES webhook_notifications(id);"
    )
  end

  defp alter_table_webhook_conversations_remove_columns_of_webhook_notifications() do
    alter table(:captain_hook_webhook_conversations) do
      remove(:webhook_endpoint_id)
      remove(:resource_type)
      remove(:resource_id)
      remove(:request_id)
    end

    drop(index(:captain_hook_webhook_conversations, [:resource_type]))
    drop(index(:captain_hook_webhook_conversations, [:resource_id]))
    drop(index(:captain_hook_webhook_conversations, [:request_id]))
  end

  defp create_webhook_endpoint_secrets_table do
    create table(:captain_hook_webhook_endpoint_secrets, primary_key: false) do
      add(:id, :uuid, primary_key: true)

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
    flush()
    seed_webhook_endpoint_secrets_for_each_webhook_endpoint()
  end

  defp seed_webhook_endpoint_secrets_for_each_webhook_endpoint() do
    %{rows: rows} =
      repo().query!(
        "SELECT id, started_at FROM captain_hook_webhook_endpoints ORDER BY inserted_at ASC"
      )

    rows
    |> Enum.each(fn [webhook_endpoint_id, started_at] ->
      started_at = DateTime.from_naive!(started_at, "Etc/UTC")

      webhook_endpoint_id =
        Ecto.UUID.cast!(webhook_endpoint_id) |> String.replace("-", "") |> String.upcase()

      secret = CaptainHook.WebhookSecrets.generate_secret()
      now = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_naive()

      execute(
        "INSERT INTO captain_hook_webhook_endpoint_secrets(webhook_endpoint_id, started_at, main, secrect, inserted_at, updated_at) VALUES ('#{
          webhook_endpoint_id
        }', '#{started_at}', 1, '#{secret}', '#{now}', '#{now}')"
      )
    end)
  end

  defp create_webhook_endpoint_enabled_notification_types_table do
    create table(:captain_hook_webhook_endpoint_enabled_notification_types) do
      add(
        :webhook_endpoint_id,
        references(:captain_hook_webhook_endpoints, on_delete: :delete_all, type: :binary_id),
        null: false
      )

      add(:name, :string, null: false)

      timestamps()
    end

    create(index(:captain_hook_webhook_endpoint_notification_types, [:name]))
  end

  defp alter_table_webhook_endpoints_remove_livemode_column() do
    alter table(:captain_hook_webhook_endpoints) do
      remove(:livemode)
    end
  end

  defp drop_sequences_table do
    drop(table(:captain_hook_sequences))
  end

  defp drop_webhook_notifications_table do
    drop(table(:captain_hook_webhook_notifications))
  end

  defp alter_table_webhook_conversations_remove_sequence_column() do
    alter table(:captain_hook_webhook_conversations) do
      remove(:sequence)
    end
  end

  defp alter_table_webhook_conversations_remove_reference_to_webhook_notifications() do
    alter table(:captain_hook_webhook_conversations) do
      remove(:webhook_notification_id)
    end
  end

  defp alter_table_webhook_conversations_revert_remove_columns_of_webhook_notifications() do
    alter table(:captain_hook_webhook_conversations) do
      add(:request_id, :binary_id, null: false)
      add(:resource_id, :string, null: true)
      add(:resource_type, :string, null: true)
    end

    create(index(:captain_hook_webhook_conversations, [:request_id]))
    create(index(:captain_hook_webhook_conversations, [:resource_id]))

    create(
      index(:captain_hook_webhook_conversations, [:resource_type, :resource_id],
        name: "captain_hook_webhook_conversations_rt_ri_index"
      )
    )
  end

  defp drop_webhook_endpoint_secrets_table do
    drop(table(:captain_hook_webhook_endpoint_secrets))
  end

  defp drop_webhook_endpoint_enabled_notification_types_table do
    drop(table(:captain_hook_webhook_endpoint_enabled_notification_types))
  end
end
