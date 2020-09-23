defmodule CaptainHook.WebhookEndpoints.WebhookEndpointQueryable do
  use AntlUtilsEcto.Queryable,
    base_schema: CaptainHook.WebhookEndpoints.WebhookEndpoint
end
