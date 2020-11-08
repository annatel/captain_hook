defmodule CaptainHook.WebhookEndpoints.WebhookEndpointQueryable do
  use AntlUtilsEcto.Queryable,
    base_schema: CaptainHook.WebhookEndpoints.WebhookEndpoint

  import Ecto.Query, only: [select: 3, where: 2]

  @spec include_secret(Ecto.Queryable.t()) :: Ecto.Queryable.t()
  def include_secret(queryable) do
    queryable
    |> select([webhook_endpoint], [
      webhook_endpoint,
      %{
        secret:
          fragment(
            "SELECT secret FROM captain_hook_webhook_secrets WHERE webhook_endpoint_id = ? and is_main = true ORDER BY started_at DESC LIMIT 1",
            webhook_endpoint.id
          )
      }
    ])
  end

  @spec filter_by_period_status(
          Ecto.Queryable.t(),
          :ended | :ongoing | :scheduled | nil | [:ended | :ongoing | :scheduled],
          DateTime.t()
        ) :: Ecto.Queryable.t()
  def filter_by_period_status(queryable, nil, _) do
    queryable
  end

  def filter_by_period_status(queryable, period_status, %DateTime{} = period_status_at) do
    queryable
    |> AntlUtilsEcto.Query.where_period_status(
      period_status,
      :started_at,
      :ended_at,
      period_status_at
    )
  end
end
