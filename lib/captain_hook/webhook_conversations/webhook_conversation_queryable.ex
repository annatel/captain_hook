defmodule CaptainHook.WebhookConversations.WebhookConversationQueryable do
  use AntlUtilsEcto.Queryable,
    base_schema: CaptainHook.WebhookConversations.WebhookConversation,
    searchable_fields: [:webhook]

  alias CaptainHook.WebhookEndpoints

  defp search_by_field({:webhook, value}, dynamic) do
    webhook_endpoint_ids =
      WebhookEndpoints.list_webhook_endpoints(value, nil) |> Enum.map(& &1.id) |> Enum.uniq()

    dynamic(
      [webhook_conversation],
      ^dynamic or webhook_conversation.webhook_endpoint_id in ^webhook_endpoint_ids
    )
  end
end
