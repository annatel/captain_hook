defmodule CaptainHook.WebhookConversations.WebhookConversationQueryable do
  @moduledoc false

  use AntlUtilsEcto.Queryable,
    base_schema: CaptainHook.WebhookConversations.WebhookConversation

  import Ecto.Query, only: [preload: 2, where: 3]

  alias CaptainHook.WebhookNotifications

  @includes [:webhook_endpoint, :webhook_notification]

  @spec includes() :: [atom]
  def includes(), do: @includes

  @spec with_preloads(Ecto.Queryable.t(), keyword) :: Ecto.Queryable.t()
  def with_preloads(queryable, includes) when is_list(includes) do
    includes
    |> Enum.reduce(queryable, fn include, queryable ->
      queryable |> with_preload(include)
    end)
  end

  defp with_preload(queryable, :webhook_notification) do
    queryable |> preload_webhook_notification()
  end

  defp filter_by_field({:webhook, value}, queryable) do
    webhook_notification_ids_query =
      WebhookNotifications.webhook_notification_queryable(
        filters: [webhook: value],
        fields: [:id]
      )
      |> Ecto.Queryable.to_query()

    queryable
    |> where(
      [webhook_conversation],
      webhook_conversation.webhook_notification_id in subquery(webhook_notification_ids_query)
    )
  end

  defp preload_webhook_notification(queryable) do
    queryable |> preload(:webhook_notification)
  end
end
