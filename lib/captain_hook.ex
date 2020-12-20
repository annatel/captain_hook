defmodule CaptainHook do
  @behaviour CaptainHook.Behaviour

  alias CaptainHook.Notifier
  alias CaptainHook.WebhookEndpoints
  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookNotifications
  alias CaptainHook.WebhookNotifications.WebhookNotification
  alias CaptainHook.WebhookConversations
  alias CaptainHook.WebhookConversations.WebhookConversation

  @spec notify(binary, boolean, binary, map, keyword) ::
          {:ok, WebhookNotification.t()} | {:error, Ecto.Changeset.t()}
  defdelegate notify(webhook, livemode?, notification_type, data, opts \\ []), to: Notifier

  @spec send_notification(WebhookEndpoint.t(), WebhookNotification.t()) ::
          {:ok, WebhookConversation.t()} | {:error, Ecto.Changeset.t()}
  defdelegate send_notification(webhook_endpoint, webhook_notification), to: Notifier

  @spec list_webhook_endpoints(keyword) :: [WebhookEndpoint.t()]
  defdelegate list_webhook_endpoints(opts \\ []), to: WebhookEndpoints

  @spec get_webhook_endpoint(binary, keyword) :: WebhookEndpoint.t() | nil
  defdelegate get_webhook_endpoint(id, opts \\ []), to: WebhookEndpoints

  @spec get_webhook_endpoint!(binary, keyword) :: WebhookEndpoint.t()
  defdelegate get_webhook_endpoint!(id, opts \\ []), to: WebhookEndpoints

  @spec create_webhook_endpoint(map()) ::
          {:ok, WebhookEndpoint.t()} | {:error, Ecto.Changeset.t()}
  defdelegate create_webhook_endpoint(attrs), to: WebhookEndpoints

  @spec update_webhook_endpoint(WebhookEndpoint.t(), map()) ::
          {:ok, WebhookEndpoint.t()} | {:error, Ecto.Changeset.t()}
  defdelegate update_webhook_endpoint(webhook_endpoint, attrs), to: WebhookEndpoints

  @spec delete_webhook_endpoint(WebhookEndpoint.t()) ::
          {:ok, WebhookEndpoint.t()} | {:error, Ecto.Changeset.t()}
  def delete_webhook_endpoint(webhook_endpoint) do
    utc_now = DateTime.utc_now()
    WebhookEndpoints.delete_webhook_endpoint(webhook_endpoint, utc_now)
  end

  @spec roll_webhook_endpoint_secret(WebhookEndpoint.t(), DateTime.t()) ::
          {:ok, Secrets.WebhookEndpointSecret.t()} | {:error, Ecto.Changeset.t()}
  defdelegate roll_webhook_endpoint_secret(webhook_endpoint, expires_at \\ DateTime.utc_now()),
    to: WebhookEndpoints

  @spec enable_notification_type(WebhookEndpoint.t(), binary | [binary]) ::
          {:ok, WebhookEndpoint.t()} | {:error, Ecto.Changeset.t()}
  defdelegate enable_notification_type(webhook_endpoint, notification_type), to: WebhookEndpoints

  @spec disable_notification_type(WebhookEndpoint.t(), binary | [binary]) ::
          {:ok, WebhookEndpoint.t()} | {:error, Ecto.Changeset.t()}
  defdelegate disable_notification_type(webhook_endpoint, notification_type), to: WebhookEndpoints

  @spec list_webhook_notifications(keyword) :: %{data: [WebhookNotification.t()], total: integer}
  defdelegate list_webhook_notifications(opts \\ []), to: WebhookNotifications

  @spec get_webhook_notification(binary, keyword) :: WebhookNotification.t() | nil
  defdelegate get_webhook_notification(id, opts \\ []), to: WebhookNotifications

  @spec get_webhook_notification!(binary, keyword) :: WebhookNotification.t()
  defdelegate get_webhook_notification!(id, opts \\ []), to: WebhookNotifications

  @spec list_webhook_conversations(keyword) :: %{data: [WebhookConversation.t()], total: integer}
  defdelegate list_webhook_conversations(opts \\ []), to: WebhookConversations

  @spec get_webhook_conversation(binary) :: WebhookConversation.t() | nil
  defdelegate get_webhook_conversation(id), to: WebhookConversations

  @spec repo :: module
  def repo() do
    Application.fetch_env!(:captain_hook, :repo)
  end
end
