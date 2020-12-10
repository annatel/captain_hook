defmodule CaptainHook.WebhookEndpoints.WebhookEndpointQueryable do
  use AntlUtilsEcto.Queryable,
    base_schema: CaptainHook.WebhookEndpoints.WebhookEndpoint

  import Ecto.Query, only: [select_merge: 3, where: 2]

  @spec include_secret(Ecto.Queryable.t()) :: Ecto.Queryable.t()
  def include_secret(queryable) do
    queryable
    |> select_merge(
      [webhook_endpoint],
      %{
        secret:
          fragment(
            "SELECT secret FROM captain_hook_webhook_secrets WHERE webhook_endpoint_id = ? and is_main = true ORDER BY started_at DESC LIMIT 1",
            webhook_endpoint.id
          )
      }
    )
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
