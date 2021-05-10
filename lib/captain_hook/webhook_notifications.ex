defmodule CaptainHook.WebhookNotifications do
  @moduledoc false

  import Ecto.Query, only: [order_by: 2]

  alias Ecto.Multi
  alias CaptainHook.Sequences
  alias CaptainHook.WebhookNotifications.{WebhookNotification, WebhookNotificationQueryable}

  @default_page_number 1
  @default_page_size 100

  @spec list_webhook_notifications(keyword) :: %{data: [WebhookNotification.t()], total: integer}
  def list_webhook_notifications(opts \\ []) do
    page_number = Keyword.get(opts, :page_number, @default_page_number)
    page_size = Keyword.get(opts, :page_size, @default_page_size)

    query = opts |> webhook_notification_queryable() |> order_by(desc: :sequence)

    count = query |> CaptainHook.repo().aggregate(:count, :id)

    webhook_notifications =
      query
      |> WebhookNotificationQueryable.paginate(page_number, page_size)
      |> CaptainHook.repo().all()

    %{total: count, data: webhook_notifications}
  end

  @spec get_webhook_notification(binary, keyword) :: WebhookNotification.t() | nil
  def get_webhook_notification(id, opts \\ []) when is_binary(id) do
    opts
    |> Keyword.put(:filters, id: id)
    |> webhook_notification_queryable()
    |> CaptainHook.repo().one()
  end

  @spec get_webhook_notification!(binary, keyword) :: WebhookNotification.t()
  def get_webhook_notification!(id, opts \\ []) when is_binary(id) do
    opts
    |> Keyword.put(:filters, id: id)
    |> webhook_notification_queryable()
    |> CaptainHook.repo().one!()
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
      |> WebhookNotification.changeset(attrs |> Map.put(:sequence, sequence))
    end)
    |> CaptainHook.repo().transaction()
    |> case do
      {:ok, %{webhook_notification: webhook_notification}} -> {:ok, webhook_notification}
      {:error, :webhook_notification, error, _} -> {:error, error}
    end
  end

  @spec webhook_notification_queryable(keyword) :: Ecto.Queryable.t()
  def webhook_notification_queryable(opts \\ []) when is_list(opts) do
    filters = Keyword.get(opts, :filters, [])
    fields = Keyword.get(opts, :fields)

    WebhookNotificationQueryable.queryable()
    |> WebhookNotificationQueryable.select_fields(fields)
    |> WebhookNotificationQueryable.filter(filters)
  end
end
