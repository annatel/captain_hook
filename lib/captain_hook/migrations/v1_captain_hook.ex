defmodule CaptainHook.Migrations.V1.CaptainHook do
  @moduledoc false

  use Ecto.Migration

  def up do
    create_webhook_endpoints_table()
    create_webhook_conversations_table()
  end

  def down do
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
      add(:headers, :map)
      add(:allow_insecure, :boolean)

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

      add(:resource_type, :string, null: true)
      add(:resource_id, :string, null: true)

      # a unique string to identify this call. This request_id will be the same for all attempts of a webhook call.
      add(:request_id, :binary_id, null: false)

      add(:requested_at, :utc_datetime, null: false)

      add(:request_url, :string, null: false)
      add(:request_headers, :map, null: true)
      add(:request_body, :text, null: true)

      add(:http_status, :integer, null: true)
      add(:response_body, :text, null: true)
      add(:client_error_message, :text, null: true)

      add(:status, :string, null: true)

      timestamps()
    end

    create(index(:captain_hook_webhook_conversations, [:resource_id]))

    create(
      index(:captain_hook_webhook_conversations, [:resource_type, :resource_id],
        name: "captain_hook_webhook_conversations_rt_ri_index"
      )
    )

    create(index(:captain_hook_webhook_conversations, [:request_id]))
    create(index(:captain_hook_webhook_conversations, [:status]))
    create(index(:captain_hook_webhook_conversations, [:inserted_at]))
  end

  defp drop_webhook_conversations_table do
    drop(table(:captain_hook_webhook_conversations))
  end
end
