defmodule CaptainHook.WebhookNotification do
  import Ecto.Query, only: [order_by: 2]

  alias CaptainHook.WebhookNotifications.{WebhookNotification, WebhookNotificationQueryable}

  @spec list_webhook_notifications(keyword) :: [WebhookNotification.t()]
  def list_webhook_notifications(opts \\ []) do
    opts
    |> webhook_notification_queryable()
    |> order_by(asc: :started_at)
    |> CaptainHook.repo().all()
  end

  @spec get_webhook_notification(binary, keyword) :: WebhookNotification.t()
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

  @spec create_webhook_notification(map()) :: WebhookNotification.t()
  def create_webhook_notification(attrs) when is_map(attrs) do
    %WebhookNotification{}
    |> WebhookNotification.changeset(attrs)
    |> CaptainHook.repo().insert()
  end

  @spec webhook_notification_queryable(keyword) :: Ecto.Queryable.t()
  def webhook_notification_queryable(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])

    WebhookNotificationQueryable.queryable()
    |> WebhookNotificationQueryable.filter(filters)
  end
end
