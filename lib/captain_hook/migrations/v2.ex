defmodule CaptainHook.Migrations.V2 do
  @moduledoc false

  use Ecto.Migration

  def up do
    alter_webhook_endpoints_table_add_headers_column()
  end

  def down do
    alter_webhook_endpoints_table_drop_headers_column()
  end

  defp alter_webhook_endpoints_table_add_headers_column do
    query =
      "ALTER TABLE captain_hook_webhook_endpoints ADD COLUMN headers JSON NULL AFTER metadata;"

    Ecto.Adapters.SQL.query!(Application.fetch_env!(:captain_hook, :repo), query, [])
  end

  defp alter_webhook_endpoints_table_drop_headers_column do
    query = "ALTER TABLE captain_hook_webhook_endpoints DROP COLUMN headers;"

    Ecto.Adapters.SQL.query!(Application.fetch_env!(:captain_hook, :repo), query, [])
  end
end
