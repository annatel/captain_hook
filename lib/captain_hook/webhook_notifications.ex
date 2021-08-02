defmodule CaptainHook.WebhookNotifications do
  @moduledoc false

  alias Ecto.Multi
  alias CaptainHook.Sequences
  alias CaptainHook.WebhookNotifications.{WebhookNotification, WebhookNotificationQueryable}

  @default_page_number 1
  @default_page_size 100

  @spec list_webhook_notifications(keyword) :: [WebhookNotification.t()]
  def list_webhook_notifications(opts \\ []) do
    try do
      opts |> webhook_notification_queryable() |> CaptainHook.repo().all()
    rescue
      Ecto.Query.CastError -> []
    end
  end

  @spec paginate_webhook_notifications(pos_integer, pos_integer, keyword) :: %{
          data: [WebhookEndpoint.t()],
          page_number: integer,
          page_size: integer,
          total: integer
        }
  def paginate_webhook_notifications(
        page_size \\ @default_page_size,
        page_number \\ @default_page_number,
        opts \\ []
      )
      when is_integer(page_number) and is_integer(page_size) do
    try do
      query = opts |> webhook_notification_queryable()

      webhook_notifications =
        query
        |> WebhookNotificationQueryable.paginate(page_size, page_number)
        |> CaptainHook.repo().all()

      %{
        data: webhook_notifications,
        page_number: page_number,
        page_size: page_size,
        total: CaptainHook.repo().aggregate(query, :count, :id)
      }
    rescue
      Ecto.Query.CastError -> %{data: [], page_number: 0, page_size: 0, total: 0}
    end
  end

  @spec get_webhook_notification(binary, keyword) :: WebhookNotification.t() | nil
  def get_webhook_notification(id, opts \\ []) when is_binary(id) do
    filters = opts |> Keyword.get(:filters, []) |> Keyword.put(:id, id)

    try do
      opts
      |> Keyword.put(:filters, filters)
      |> webhook_notification_queryable()
      |> CaptainHook.repo().one()
    rescue
      Ecto.Query.CastError -> nil
    end
  end

  @spec get_webhook_notification!(binary, keyword) :: WebhookNotification.t()
  def get_webhook_notification!(id, opts \\ []) when is_binary(id) do
    opts
    |> Keyword.put(:filters, id: id)
    |> webhook_notification_queryable()
    |> CaptainHook.repo().one!()
  end

  @spec get_webhook_notification_by(keyword, keyword) :: WebhookNotification.t()
  def get_webhook_notification_by([idempotency_key: idempotency_key], opts \\ []) do
    filters = opts |> Keyword.get(:filters, []) |> Keyword.put(:idempotency_key, idempotency_key)

    try do
      opts
      |> Keyword.put(:filters, filters)
      |> webhook_notification_queryable()
      |> CaptainHook.repo().one()
    rescue
      Ecto.Query.CastError -> nil
    end
  end

  @spec create_webhook_notification(map()) ::
          {:ok, WebhookNotification.t()} | {:error, Ecto.Changeset.t()}
  def create_webhook_notification(attrs) when is_map(attrs) do
    Multi.new()
    |> Multi.run(:sequence, fn _repo, %{} ->
      {:ok, Sequences.next_value!(:webhook_notifications)}
    end)
    |> Multi.insert(:webhook_notification, fn %{sequence: sequence} ->
      %WebhookNotification{}
      |> WebhookNotification.create_changeset(attrs |> Map.put(:sequence, sequence))
    end)
    |> CaptainHook.repo().transaction()
    |> case do
      {:ok, %{webhook_notification: webhook_notification}} -> {:ok, webhook_notification}
      {:error, :webhook_notification, error, _} -> {:error, error}
    end
  end

  @spec update_webhook_notification(WebhookNotification.t(), map()) ::
          {:ok, WebhookNotification.t()} | {:error, Ecto.Changeset.t()}
  def update_webhook_notification(%WebhookNotification{} = webhook_notification, attrs)
      when is_map(attrs) do
    webhook_notification
    |> WebhookNotification.update_changeset(attrs)
    |> CaptainHook.repo().update()
  end

  @spec notification_succeeded?(WebhookNotification.t()) :: boolean
  def notification_succeeded?(%WebhookNotification{succeeded_at: succeeded_at}) do
    not is_nil(succeeded_at)
  end

  @spec webhook_notification_queryable(keyword) :: Ecto.Queryable.t()
  def webhook_notification_queryable(opts \\ []) when is_list(opts) do
    filters = Keyword.get(opts, :filters, [])
    includes = opts |> Keyword.get(:includes, [])
    select_fields = Keyword.get(opts, :fields)

    WebhookNotificationQueryable.queryable()
    |> WebhookNotificationQueryable.filter(filters)
    |> WebhookNotificationQueryable.include(includes)
    |> WebhookNotificationQueryable.order_by(desc: :sequence)
    |> WebhookNotificationQueryable.select_fields(select_fields)
  end
end
