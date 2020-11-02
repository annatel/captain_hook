defmodule CaptainHook.WebhookEndpoints.WebhookEndpointQueryable do
  use AntlUtilsEcto.Queryable,
    base_schema: CaptainHook.WebhookEndpoints.WebhookEndpoint

  import Ecto.Query, only: [select: 3, where: 2]

  @spec with_secret(Ecto.Queryable.t()) :: Ecto.Queryable.t()
  def with_secret(queryable) do
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
end
