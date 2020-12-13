defmodule CaptainHook.WebhookEndpoints.WebhookEndpointQueryable do
  use AntlUtilsEcto.Queryable,
    base_schema: CaptainHook.WebhookEndpoints.WebhookEndpoint

  import Ecto.Query, only: [preload: 2, select_merge: 3, where: 2]

  @spec with_preloads(Ecto.Queryable.t(), list) :: Ecto.Queryable.t()
  def with_preloads(queryable, includes) when is_list(includes) do
    includes
    |> Enum.reduce(queryable, fn include, queryable ->
      queryable |> with_preload(include)
    end)
  end

  defp with_preload(queryable, :secret) do
    queryable |> preload_secret()
  end

  defp with_preload(queryable, :enabled_notification_types) do
    queryable |> preload_enabled_notification_types()
  end

  @spec preload_secret(Ecto.Queryable.t()) :: Ecto.Queryable.t()
  def preload_secret(queryable) do
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

  def preload_enabled_notification_types(queryable) do
    queryable |> preload(:enabled_notification_types)
  end

  defp filter_by_field({:ended_at, %DateTime{} = datetime}, queryable) do
    queryable
    |> AntlUtilsEcto.Query.where_period_status(:ended, :started_at, :ended_at, datetime)
  end

  defp filter_by_field({:ongoing_at, %DateTime{} = datetime}, queryable) do
    queryable
    |> AntlUtilsEcto.Query.where_period_status(:ongoing, :started_at, :ended_at, datetime)
  end

  defp filter_by_field({:scheduled_at, %DateTime{} = datetime}, queryable) do
    queryable
    |> AntlUtilsEcto.Query.where_period_status(:scheduled, :started_at, :ended_at, datetime)
  end
end
