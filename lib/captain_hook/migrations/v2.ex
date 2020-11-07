defmodule CaptainHook.Migrations.V2 do
  @moduledoc false

  use Ecto.Migration

  def up do
    alter_table_webhook_endpoints_add_livemode_column()
    alter_table_webhook_conversations_rename_request_id_column()
    alter_table_webhook_conversations_add_notification_type_column()
    alter_table_webhook_conversations_add_sequence_column()
    create_sequences_table()
    create_webhook_secrets_table()
    create_webhook_notification_types_table()
  end

  def down do
    alter_table_webhook_endpoints_remove_livemode_column()
    alter_table_webhook_conversations_revert_rename_request_id_column()
    alter_table_webhook_conversations_remove_notification_type_column()
    alter_table_webhook_conversations_remove_sequence_column()
    drop_sequences_table()
    drop_webhook_secrets_table()
    drop_webhook_notification_types_table()
  end

  defp alter_table_webhook_endpoints_add_livemode_column() do
    execute(
      "ALTER TABLE captain_hook_webhook_endpoints ADD COLUMN livemode TINYINT(1) NOT NULL AFTER ended_at;"
    )

    create(index(:captain_hook_webhook_endpoints, [:livemode]))

    execute("UPDATE captain_hook_webhook_endpoints SET livemode = 1")
  end

  defp alter_table_webhook_endpoints_remove_livemode_column() do
    alter table(:captain_hook_webhook_endpoints) do
      remove(:livemode)
    end
  end

  defp alter_table_webhook_conversations_rename_request_id_column() do
    execute(
      "ALTER TABLE captain_hook_webhook_conversations CHANGE request_id notification_id BINARY(16) NOT NULL"
    )

    create(index(:captain_hook_webhook_conversations, [:notification_id]))
  end

  defp alter_table_webhook_conversations_revert_rename_request_id_column() do
    execute(
      "ALTER TABLE webhook_conversations CHANGE notification_id request_id BINARY(16) NOT NULL"
    )

    drop(index(:captain_hook_webhook_conversations, [:notification_id]))
    create(index(:captain_hook_webhook_conversations, [:request_id]))
  end

  defp alter_table_webhook_conversations_add_notification_type_column() do
    execute(
      "ALTER TABLE captain_hook_webhook_conversations ADD COLUMN notification_type VARCHAR(255) NOT NULL AFTER notification_id;"
    )

    create(index(:captain_hook_webhook_conversations, [:notification_type]))
  end

  defp alter_table_webhook_conversations_remove_notification_type_column() do
    alter table(:captain_hook_webhook_conversations) do
      remove(:notification_type)
    end
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

  defp alter_table_webhook_conversations_remove_sequence_column() do
    alter table(:captain_hook_webhook_conversations) do
      remove(:sequence)
    end
  end

  defp create_sequences_table do
    create table(:captain_hook_sequences) do
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
  end

  defp drop_sequences_table do
    drop(table(:captain_hook_sequences))
  end

  defp create_webhook_secrets_table do
    create table(:captain_hook_webhook_secrets, primary_key: false) do
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

    create(index(:captain_hook_webhook_secrets, [:is_main]))
    create(index(:captain_hook_webhook_secrets, [:started_at]))
    create(index(:captain_hook_webhook_secrets, [:ended_at]))
    flush()
    seed_webhook_secrets_for_each_webhook_endpoint()
  end

  defp seed_webhook_secrets_for_each_webhook_endpoint() do
    %{rows: rows} =
      repo().query!(
        "SELECT id, started_at FROM captain_hook_webhook_endpoints ORDER BY inserted_at ASC"
      )

    rows
    |> Enum.each(fn [id, started_at] ->
      started_at = DateTime.from_naive!(started_at, "Etc/UTC")
      id = Ecto.UUID.cast!(id)

      CaptainHook.WebhookSecrets.create_webhook_secret(
        %CaptainHook.WebhookEndpoints.WebhookEndpoint{id: id},
        started_at
      )
    end)
  end

  defp drop_webhook_secrets_table do
    drop(table(:captain_hook_webhook_secrets))
  end

  defp create_webhook_notification_types_table do
    create table(:captain_hook_webhook_notification_types, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(
        :webhook_endpoint_id,
        references(:captain_hook_webhook_endpoints, on_delete: :delete_all, type: :binary_id),
        null: false
      )

      add(:type, :string, null: false)

      timestamps()
    end

    create(index(:captain_hook_webhook_notification_types, [:type]))
  end

  defp drop_webhook_notification_types_table do
    drop(table(:captain_hook_webhook_notification_types))
  end
end
