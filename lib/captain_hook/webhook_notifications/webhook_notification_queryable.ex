defmodule CaptainHook.WebhookNotifications.WebhookNotificationQueryable do
  @moduledoc false

  use AntlUtilsEcto.Queryable,
    base_schema: CaptainHook.WebhookNotifications.WebhookNotification

  import Ecto.Query, only: [preload: 2]

  alias CaptainHook.WebhookEndpoints

  defp include_assoc(queryable, :webhook_endpoint) do
    queryable |> preload_webhook_endpoint()
  end

  defp preload_webhook_endpoint(queryable) do
    webhook_endpoint_query =
      WebhookEndpoints.webhook_endpoint_queryable() |> Ecto.Queryable.to_query()

    queryable |> preload(webhook_endpoint: ^webhook_endpoint_query)
  end

  defp filter_by_field(queryable, {:has_succeeded, true}) do
    queryable
    |> AntlUtilsEcto.Query.where_not(:succeeded_at, nil)
  end

  defp filter_by_field(queryable, {:has_succeeded, false}) do
    queryable
    |> AntlUtilsEcto.Query.where(:succeeded_at, nil)
  end
end
