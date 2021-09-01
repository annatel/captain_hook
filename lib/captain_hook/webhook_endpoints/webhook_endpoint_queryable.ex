defmodule CaptainHook.WebhookEndpoints.WebhookEndpointQueryable do
  @moduledoc false

  use AntlUtilsEcto.Queryable,
    base_schema: CaptainHook.WebhookEndpoints.WebhookEndpoint

  import Ecto.Query, only: [preload: 2, select_merge: 3, where: 2]

  def queryable() do
    super()
    |> AntlUtilsEcto.Query.where(:deleted_at, nil)
  end

  defp include_assoc(queryable, :secret) do
    queryable |> preload_secret()
  end

  defp include_assoc(queryable, :enabled_notification_patterns) do
    queryable |> preload_enabled_notification_patterns()
  end

  defp preload_enabled_notification_patterns(queryable) do
    queryable |> preload(:enabled_notification_patterns)
  end

  defp preload_secret(queryable) do
    queryable
    |> select_merge(
      [webhook_endpoint],
      %{
        secret:
          fragment(
            "SELECT secret FROM captain_hook_webhook_endpoint_secrets WHERE webhook_endpoint_id = ? and is_main = true ORDER BY started_at DESC LIMIT 1",
            webhook_endpoint.id
          )
      }
    )
  end

  defp filter_by_field(queryable, {:with_trashed, true}) do
    queryable
    |> AntlUtilsEcto.Query.or_where_not(:deleted_at, nil)
  end

  defp filter_by_field(queryable, {:only_trashed, true}) do
    queryable
    |> CaptainHook.Extensions.Ecto.Query.exclude_where_field(:deleted_at)
    |> AntlUtilsEcto.Query.where_not(:deleted_at, nil)
  end
end
