defmodule CaptainHook.Migrations.V1 do
  @moduledoc false

  use Ecto.Migration

  def up do
    Queuetopia.Migrations.V1.up()

    create_webhook_endpoints_table()
    create_webhook_conversations_table()
  end

  def down do
    Queuetopia.Migrations.V1.down()

    drop_webhook_endpoints_table()
    drop_webhook_conversations_table()
  end

  defp create_webhook_endpoints_table do
    create table(:captain_hook_webhook_endpoints, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:webhook, :string, null: false)

      add(:started_at, :utc_datetime, null: false)
      add(:ended_at, :utc_datetime, null: true)

      add(:url, :string)
      add(:metadata, :map)

      timestamps()
    end

    create(index(:captain_hook_webhook_endpoints, [:webhook]))
    create(index(:captain_hook_webhook_endpoints, [:started_at]))
    create(index(:captain_hook_webhook_endpoints, [:ended_at]))
  end

  defp drop_webhook_endpoints_table do
    drop(table(:captain_hook_webhook_endpoints))
  end

  defp create_webhook_conversations_table do
    create table(:captain_hook_webhook_conversations, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(
        :webhook_endpoint_id,
        references(:captain_hook_webhook_endpoints, on_delete: :nothing, type: :binary_id),
        null: false
      )

      add(:schema_type, :string, null: false)
      add(:schema_id, :string, null: false)

      add(:requested_at, :utc_datetime, null: false)

      add(:request_url, :string, null: false)
      add(:request_body, :text, null: true)

      add(:http_status, :integer, null: true)
      add(:response_body, :text, null: true)
      add(:client_error_message, :text, null: true)

      add(:status, :string, null: true)

      timestamps()
    end

    create(index(:captain_hook_webhook_conversations, [:status]))
    create(index(:captain_hook_webhook_conversations, [:schema_id]))
    create(index(:captain_hook_webhook_conversations, [:schema_type, :schema_id]))
  end

  defp drop_webhook_conversations_table do
    drop(table(:captain_hook_webhook_conversations))
  end
end
