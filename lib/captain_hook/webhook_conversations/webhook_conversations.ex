defmodule CaptainHook.WebhookConversations do
  import Ecto.Query, only: [order_by: 2]

  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookConversations.{WebhookConversation, WebhookConversationQueryable}

  @spec list_webhook_conversations(
          binary,
          binary | {binary, binary} | CaptainHook.WebhookEndpoints.WebhookEndpoint.t(),
          %{opts: keyword, page: number}
        ) :: %{items: [WebhookConversation.t()], total: integer}
  def list_webhook_conversations(
        webhook,
        filter,
        pagination \\ %{page: 1, opts: [per_page: 100]}
      )

  def list_webhook_conversations(
        webhook,
        %WebhookEndpoint{id: webhook_endpoint_id},
        %{page: page, opts: opts} = _pagination
      )
      when is_binary(webhook) do
    query = list_webhook_conversations_query(webhook, webhook_endpoint_id: webhook_endpoint_id)

    conversations_count = query |> CaptainHook.repo().aggregate(:count, :id)

    conversations =
      query |> WebhookConversationQueryable.paginate(page, opts) |> CaptainHook.repo().all()

    %{total: conversations_count, items: conversations}
  end

  def list_webhook_conversations(webhook, request_id, %{page: page, opts: opts} = _pagination)
      when is_binary(webhook) and is_binary(request_id) do
    query = list_webhook_conversations_query(webhook, request_id: request_id)

    conversations_count = query |> CaptainHook.repo().aggregate(:count, :id)

    conversations =
      query |> WebhookConversationQueryable.paginate(page, opts) |> CaptainHook.repo().all()

    %{total: conversations_count, items: conversations}
  end

  def list_webhook_conversations(
        webhook,
        {resource_type, resource_id},
        %{page: page, opts: opts} = _pagination
      )
      when is_binary(webhook) and is_binary(resource_type) and is_binary(resource_id) do
    query =
      list_webhook_conversations_query(webhook,
        resource_type: resource_type,
        resource_id: resource_id
      )

    conversations_count = query |> CaptainHook.repo().aggregate(:count, :id)

    conversations =
      query |> WebhookConversationQueryable.paginate(page, opts) |> CaptainHook.repo().all()

    %{total: conversations_count, items: conversations}
  end

  @spec get_webhook_conversation(binary(), binary()) :: WebhookConversation.t()
  def get_webhook_conversation(webhook, id) when is_binary(webhook) and is_binary(id) do
    WebhookConversationQueryable.queryable()
    |> WebhookConversationQueryable.search(webhook)
    |> WebhookConversationQueryable.filter(id: id)
    |> CaptainHook.repo().one()
  end

  @spec create_webhook_conversation(WebhookEndpoint.t(), map()) :: WebhookConversation.t()
  def create_webhook_conversation(%WebhookEndpoint{id: webhook_endpoint_id}, attrs)
      when is_map(attrs) do
    attrs = attrs |> Map.put(:webhook_endpoint_id, webhook_endpoint_id)

    %WebhookConversation{}
    |> WebhookConversation.changeset(attrs)
    |> CaptainHook.repo().insert()
  end

  @spec conversation_succeeded?(WebhookConversation.t()) :: boolean
  def conversation_succeeded?(%WebhookConversation{status: status}) do
    status == WebhookConversation.status().success
  end

  defp list_webhook_conversations_query(webhook, filters)
       when is_binary(webhook) and is_list(filters) do
    WebhookConversationQueryable.queryable()
    |> WebhookConversationQueryable.search(webhook)
    |> WebhookConversationQueryable.filter(filters)
    |> order_by([:inserted_at])
  end
end
