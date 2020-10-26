defmodule CaptainHook.Migrations.V2 do
  @moduledoc false

  use Ecto.Migration

  def up do
    create_webhook_secrets_table()
    create_webhook_events_table()
  end

  def down do
    drop_webhook_secrets_table()
    drop_webhook_events_table()
  end

  defp create_webhook_secrets_table do
    create table(:captain_hook_webhook_secrets, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:secret, :string, null: false)

      add(:started_at, :utc_datetime, null: false)
      add(:ended_at, :utc_datetime, null: true)

      timestamps()
    end

    create(index(:captain_hook_webhook_endpoints, [:started_at]))
    create(index(:captain_hook_webhook_endpoints, [:ended_at]))
  end

  defp drop_webhook_secrets_table do
    drop(table(:captain_hook_webhook_secrets))
  end

  defp create_webhook_events_table do
    create table(:captain_hook_webhook_events, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(
        :webhook_endpoint_id,
        references(:captain_hook_webhook_endpoints, on_delete: :delete_all, type: :binary_id),
        null: false
      )

      add(:ref, :string, null: true)

      timestamps()
    end
  end

  defp drop_webhook_events_table do
    drop(table(:captain_hook_webhook_events))
  end
end
