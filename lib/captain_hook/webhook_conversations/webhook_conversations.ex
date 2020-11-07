defmodule CaptainHook.WebhookConversations do
  import Ecto.Query, only: [order_by: 2]

  alias Ecto.Multi
  alias CaptainHook.Sequences
  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookConversations.{WebhookConversation, WebhookConversationQueryable}

  @spec list_webhook_conversations(
          binary,
          binary | {binary, binary} | WebhookEndpoint.t(),
          %{opts: keyword, page: number}
        ) :: %{total: integer, data: [WebhookConversation.t()]}
  def list_webhook_conversations(webhook, filter, pagination \\ %{page: 1, opts: [per_page: 100]})

  def list_webhook_conversations(webhook, %WebhookEndpoint{id: webhook_endpoint_id}, pagination)
      when is_binary(webhook) do
    list_webhook_conversations(webhook, [webhook_endpoint_id: webhook_endpoint_id], pagination)
  end

  def list_webhook_conversations(webhook, notification_id, pagination)
      when is_binary(webhook) and is_binary(notification_id) do
    list_webhook_conversations(webhook, [notification_id: notification_id], pagination)
  end

  def list_webhook_conversations(webhook, {resource_type, resource_id}, pagination)
      when is_binary(webhook) and is_binary(resource_type) and is_binary(resource_id) do
    list_webhook_conversations(
      webhook,
      [resource_type: resource_type, resource_id: resource_id],
      pagination
    )
  end

  def list_webhook_conversations(
        webhook,
        filters,
        %{page: page, opts: opts} = _pagination
      )
      when is_binary(webhook) do
    query = list_webhook_conversations_query(webhook, filters)

    conversations_count = query |> CaptainHook.repo().aggregate(:count, :id)

    conversations =
      query |> WebhookConversationQueryable.paginate(page, opts) |> CaptainHook.repo().all()

    %{total: conversations_count, data: conversations}
  end

  def list_webhook_conversations(webhook, filters, opts)
      when is_binary(webhook) and is_list(opts) do
    pagination_params = Keyword.get(opts, :pagination_params, %{page: 1, opts: []})

    query =
      WebhookConversationQueryable.queryable()
      |> WebhookConversationQueryable.search(webhook)
      |> WebhookConversationQueryable.filter(filters)
      |> order_by([:sequence])

    webhook_conversations =
      query
      |> WebhookConversationQueryable.paginate(pagination_params.page, pagination_params.opts)
      |> CaptainHook.repo().all()

    count = query |> CaptainHook.repo().aggregate(:count, :id)

    %{total: count, data: webhook_conversations}
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

    Multi.new()
    |> Multi.run(:sequence, fn _repo, %{} ->
      {:ok, Sequences.next(:webhook_conversations)}
    end)
    |> Multi.insert(:webhook_conversation, fn %{sequence: sequence} ->
      %WebhookConversation{}
      |> WebhookConversation.changeset(attrs |> Map.put(:sequence, sequence))
    end)
    |> CaptainHook.repo().transaction()
    |> case do
      {:ok, %{webhook_conversation: webhook_conversation}} -> {:ok, webhook_conversation}
      {:error, :webhook_conversation, error, _} -> {:error, error}
    end
  end

  @spec conversation_succeeded?(WebhookConversation.t()) :: boolean
  def conversation_succeeded?(%WebhookConversation{status: status}) do
    status == WebhookConversation.status().success
  end
end
