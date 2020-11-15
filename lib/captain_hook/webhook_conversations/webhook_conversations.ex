defmodule CaptainHook.WebhookConversations do
  import Ecto.Query, only: [order_by: 2]

  alias Ecto.Multi
  alias CaptainHook.Sequences
  alias CaptainHook.WebhookConversations.{WebhookConversation, WebhookConversationQueryable}

  @default_page_number 1
  @default_page_size 100

  @spec list_webhook_conversations(keyword) :: %{data: any, total: any}
  def list_webhook_conversations(opts \\ []) when is_list(opts) do
    livemode = Keyword.get(opts, :livemode)

    filters = Keyword.get(opts, :filters, []) |> Map.put(:livemode, livemode)
    search_query = Keyword.get(opts, :search_query)

    page_number = Keyword.get(opts, :page_number, @default_page_number)
    page_size = Keyword.get(opts, :page_size, @default_page_size)

    query =
      WebhookConversationQueryable.queryable()
      |> WebhookConversationQueryable.search(search_query, livemode: livemode)
      |> WebhookConversationQueryable.filter(filters)
      |> order_by([:sequence])

    count = query |> CaptainHook.repo().aggregate(:count, :id)

    webhook_conversations =
      query
      |> WebhookConversationQueryable.paginate(page_number, page_size)
      |> CaptainHook.repo().all()

    %{total: count, data: webhook_conversations}
  end

  def list_webhook_conversations({webhook, resource_type, resource_id}, opts)
      when is_binary(webhook) and is_binary(resource_type) and is_binary(resource_id) do
    opts
    |> Keyword.put(:filters, resource_type: resource_type, resource_id: resource_id)
    |> Keyword.put(:search_query, webhook)
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
