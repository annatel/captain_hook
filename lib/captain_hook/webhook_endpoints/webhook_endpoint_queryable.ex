defmodule CaptainHook.WebhookEndpoints.WebhookEndpointQueryable do
  use AntlUtils.Ecto.Queryable,
    base_schema: CaptainHook.WebhookEndpoints.WebhookEndpoint
end
