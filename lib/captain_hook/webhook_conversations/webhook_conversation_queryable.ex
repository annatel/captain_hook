defmodule CaptainHook.WebhookConversations.WebhookConversationQueryable do
  @moduledoc false

  use AntlUtilsEcto.Queryable,
    base_schema: CaptainHook.WebhookConversations.WebhookConversation

  import Ecto.Query, only: [preload: 2, where: 3]

  alias CaptainHook.WebhookNotifications

  defp include_assoc(queryable, :webhook_notification) do
    queryable |> preload_webhook_notification()
  end

  defp preload_webhook_notification(queryable) do
    queryable |> preload(:webhook_notification)
  end

  defp filter_by_field(queryable, {:webhook_endpoint_id, webhook_endpoint_id}) do
    webhook_notification_ids_query =
      WebhookNotifications.webhook_notification_queryable(
        filters: [webhook_endpoint_id: webhook_endpoint_id],
        fields: [:id]
      )
      |> Ecto.Queryable.to_query()

    queryable
    |> where(
      [webhook_conversation],
      webhook_conversation.webhook_notification_id in subquery(webhook_notification_ids_query)
    )
  end
end
