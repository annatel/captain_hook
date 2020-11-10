defmodule CaptainHook.WebhookConversations do
  import Ecto.Query, only: [order_by: 2]

  alias Ecto.Multi
  alias CaptainHook.Sequences
  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookConversations.{WebhookConversation, WebhookConversationQueryable}

  @spec list_webhook_conversations(keyword) :: %{data: any, total: any}
  def list_webhook_conversations(opts) when is_list(opts) do
    search_query = Keyword.get(opts, :search_query)
    livemode = Keyword.get(opts, :livemode)
    filters = Keyword.get(opts, :filters)
    pagination = Keyword.get(opts, :pagination)

    query =
      WebhookConversationQueryable.queryable()
      |> WebhookConversationQueryable.search(search_query, livemode: livemode)
      |> WebhookConversationQueryable.filter(filters)
      |> order_by([:sequence])

    query =
      if pagination do
        {page_number, page_size} = pagination
        query |> WebhookConversationQueryable.paginate(page_number, page_size)
      else
        query
      end

    webhook_conversations = query |> CaptainHook.repo().all()

    count = query |> CaptainHook.repo().aggregate(:count, :id)

    %{total: count, data: webhook_conversations}
  end

  @spec list_webhook_conversations(
          binary | {binary, binary, binary} | CaptainHook.WebhookEndpoints.WebhookEndpoint.t(),
          keyword
        ) :: %{data: any, total: any}
  def list_webhook_conversations(filter, opts \\ [])

  def list_webhook_conversations(%WebhookEndpoint{id: webhook_endpoint_id}, opts) do
    opts
    |> Keyword.put(:filters, webhook_endpoint_id: webhook_endpoint_id)
    |> list_webhook_conversations()
  end

  def list_webhook_conversations(notification_id, opts) when is_binary(notification_id) do
    opts
    |> Keyword.put(:filters, notification_id: notification_id)
    |> list_webhook_conversations()
  end

  def list_webhook_conversations({webhook, livemode, resource_type, resource_id}, opts)
      when is_binary(webhook) and is_binary(resource_type) and is_binary(resource_id) do
    opts
    |> Keyword.put(:filters, resource_type: resource_type, resource_id: resource_id)
    |> Keyword.put(:search_query, webhook)
    |> Keyword.put(:livemode, livemode)
    |> list_webhook_conversations()
  end

  @spec get_webhook_conversation(binary()) :: WebhookConversation.t()
  def get_webhook_conversation(id) when is_binary(id) do
    WebhookConversationQueryable.queryable()
    |> WebhookConversationQueryable.filter(id: id)
    |> CaptainHook.repo().one()
  end

  @spec create_webhook_conversation(map()) :: WebhookConversation.t()
  def create_webhook_conversation(attrs) when is_map(attrs) do
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
