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

  @spec filter_by_status(
          Ecto.Queryable.t(),
          nil | AntlUtilsEcto.Query.status() | list(AntlUtilsEcto.Query.status()),
          DateTime.t()
        ) ::
          Ecto.Queryable.t()
  def filter_by_status(queryable, nil, _) do
    queryable
  end

  def filter_by_status(queryable, status, %DateTime{} = datetime) do
    queryable
    |> AntlUtilsEcto.Query.where_period_status(status, :started_at, :ended_at, datetime)
  end
end
