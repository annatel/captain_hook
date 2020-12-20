defmodule CaptainHook.WebhookConversations do
  import Ecto.Query, only: [order_by: 2]

  alias Ecto.Multi
  alias CaptainHook.Sequences
  alias CaptainHook.WebhookConversations.{WebhookConversation, WebhookConversationQueryable}

  @default_page_number 1
  @default_page_size 100

  @spec list_webhook_conversations(keyword) :: %{data: [WebhookConversation.t()], total: integer}
  def list_webhook_conversations(opts \\ []) when is_list(opts) do
    page_number = Keyword.get(opts, :page_number, @default_page_number)
    page_size = Keyword.get(opts, :page_size, @default_page_size)

    query = opts |> webhook_conversation_queryable() |> order_by(desc: :sequence)

    count = query |> CaptainHook.repo().aggregate(:count, :id)

    webhook_conversations =
      query
      |> WebhookConversationQueryable.paginate(page_number, page_size)
      |> CaptainHook.repo().all()

    %{total: count, data: webhook_conversations}
  end

  @spec get_webhook_conversation(binary, keyword) :: WebhookConversation.t() | nil
  def get_webhook_conversation(id, opts \\ []) when is_binary(id) do
    opts
    |> Keyword.put(:filters, id: id)
    |> webhook_conversation_queryable()
    |> CaptainHook.repo().one()
  end

  @spec create_webhook_conversation(map()) ::
          {:ok, WebhookConversation.t()} | {:error, Ecto.Changeset.t()}
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

  @spec webhook_conversation_queryable(keyword) :: Ecto.Queryable.t()
  def webhook_conversation_queryable(opts) when is_list(opts) do
    filters = Keyword.get(opts, :filters, [])
    includes = Keyword.get(opts, :includes, [])

    WebhookConversationQueryable.queryable()
    |> WebhookConversationQueryable.filter(filters)
    |> WebhookConversationQueryable.with_preloads(includes)
  end
end
