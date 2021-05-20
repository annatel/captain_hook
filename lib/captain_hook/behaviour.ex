defmodule CaptainHook.Behaviour do
  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookNotifications.WebhookNotification
  alias CaptainHook.WebhoookConversations.WebhookConversation

  @callback notify(binary | [binary], boolean, binary, map, keyword) ::
              {:ok, [WebhookNotification.t()]} | {:error, Ecto.Changeset.t()}

  @callback async_notify(binary | [binary], boolean, binary, map, keyword) ::
              {:ok, [WebhookNotification.t()]} | {:error, Ecto.Changeset.t()}

  @callback send_webhook_notification!(WebhookNotification.t()) ::
              %{
                webhook_conversation: WebhookConversation.t(),
                webhook_notification: WebhookNotification.t()
              }

  @callback list_webhook_endpoints(keyword) :: [WebhookEndpoint.t()]
  @callback get_webhook_endpoint(binary, keyword) :: WebhookEndpoint.t() | nil
  @callback get_webhook_endpoint!(binary, keyword) :: WebhookEndpoint.t()
  @callback create_webhook_endpoint(map()) ::
              {:ok, WebhookEndpoint.t()} | {:error, Ecto.Changeset.t()}
  @callback update_webhook_endpoint(WebhookEndpoint.t(), map()) ::
              {:ok, WebhookEndpoint.t()} | {:error, Ecto.Changeset.t()}
  @callback delete_webhook_endpoint(WebhookEndpoint.t()) ::
              {:ok, WebhookEndpoint.t()} | {:error, Ecto.Changeset.t()}
  @callback roll_webhook_endpoint_secret(WebhookEndpoint.t(), DateTime.t()) ::
              {:ok, Secrets.WebhookEndpointSecret.t()} | {:error, Ecto.Changeset.t()}
  @callback enable_notification_type(WebhookEndpoint.t(), binary | [binary]) ::
              {:ok, WebhookEndpoint.t()} | {:error, Ecto.Changeset.t()}
  @callback disable_notification_type(WebhookEndpoint.t(), binary | [binary]) ::
              {:ok, WebhookEndpoint.t()} | {:error, Ecto.Changeset.t()}

  @callback list_webhook_notifications(keyword) :: %{
              data: [WebhookNotification.t()],
              total: integer
            }
  @callback get_webhook_notification(binary, keyword) :: WebhookNotification.t() | nil
  @callback get_webhook_notification!(binary, keyword) :: WebhookNotification.t()

  @callback list_webhook_conversations(keyword) :: %{
              data: [WebhookConversation.t()],
              total: integer
            }
  @callback get_webhook_conversation(binary, keyword) :: WebhookConversation.t() | nil
end
