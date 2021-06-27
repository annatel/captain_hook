defmodule CaptainHook.WebhookConversations do
  @moduledoc false

  alias Ecto.Multi
  alias CaptainHook.Sequences
  alias CaptainHook.WebhookConversations.{WebhookConversation, WebhookConversationQueryable}

  @default_page_number 1
  @default_page_size 100

  @spec list_webhook_conversations(keyword) :: [WebhookConversation.t()]
  def list_webhook_conversations(opts \\ []) when is_list(opts) do
    try do
      opts |> webhook_conversation_queryable() |> CaptainHook.repo().all()
    rescue
      Ecto.Query.CastError -> []
    end
  end

  @spec paginate_webhook_conversations(pos_integer, pos_integer, keyword) :: %{
          data: [WebhookEndpoint.t()],
          page_number: integer,
          page_size: integer,
          total: integer
        }
  def paginate_webhook_conversations(
        page_size \\ @default_page_size,
        page_number \\ @default_page_number,
        opts \\ []
      )
      when is_integer(page_number) and is_integer(page_size) do
    try do
      query = opts |> webhook_conversation_queryable()

      webhook_conversations =
        query
        |> WebhookConversationQueryable.paginate(page_size, page_number)
        |> CaptainHook.repo().all()

      %{
        data: webhook_conversations,
        page_number: page_number,
        page_size: page_size,
        total: CaptainHook.repo().aggregate(query, :count, :id)
      }
    rescue
      Ecto.Query.CastError -> %{data: [], page_number: 0, page_size: 0, total: 0}
    end
  end

  @spec get_webhook_conversation(binary, keyword) :: WebhookConversation.t() | nil
  def get_webhook_conversation(id, opts \\ []) when is_binary(id) do
    filters = opts |> Keyword.get(:filters, []) |> Keyword.put(:id, id)

    try do
      opts
      |> Keyword.put(:filters, filters)
      |> webhook_conversation_queryable()
      |> CaptainHook.repo().one()
    rescue
      Ecto.Query.CastError -> nil
    end
  end

  @spec create_webhook_conversation(map()) ::
          {:ok, WebhookConversation.t()} | {:error, Ecto.Changeset.t()}
  def create_webhook_conversation(attrs) when is_map(attrs) do
    Multi.new()
    |> Multi.run(:sequence, fn _repo, %{} ->
      {:ok, Sequences.next_value!(:webhook_conversations)}
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
    status == WebhookConversation.statuses().succeeded
  end

  @spec webhook_conversation_queryable(keyword) :: Ecto.Queryable.t()
  def webhook_conversation_queryable(opts) when is_list(opts) do
    filters = Keyword.get(opts, :filters, [])
    includes = Keyword.get(opts, :includes, [])

    WebhookConversationQueryable.queryable()
    |> WebhookConversationQueryable.filter(filters)
    |> WebhookConversationQueryable.include(includes)
    |> WebhookConversationQueryable.order_by(desc: :sequence)
  end
end
