defmodule CaptainHook do
  @behaviour CaptainHook.Behaviour

  alias CaptainHook.Notifier
  alias CaptainHook.WebhookEndpoints
  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookNotifications
  alias CaptainHook.WebhookNotifications.WebhookNotification
  alias CaptainHook.WebhookConversations
  alias CaptainHook.WebhookConversations.WebhookConversation

  defmacro __using__(_opts) do
    quote do
      @behaviour CaptainHook.Behaviour

      def notify(webhook, livemode?, notification_type, data, opts \\ []),
        do: unquote(__MODULE__).notify(webhook, livemode?, notification_type, data, opts)

      def send_webhook_notification(webhook_endpoint, webhook_notification),
        do: unquote(__MODULE__).send_webhook_notification(webhook_endpoint, webhook_notification)

      def list_webhook_endpoints(opts \\ []),
        do: unquote(__MODULE__).list_webhook_endpoints(opts)

      def get_webhook_endpoint(id, opts \\ []),
        do: unquote(__MODULE__).get_webhook_endpoint(id, opts)

      def get_webhook_endpoint!(id, opts \\ []),
        do: unquote(__MODULE__).get_webhook_endpoint!(id, opts)

      def create_webhook_endpoint(attrs), do: unquote(__MODULE__).create_webhook_endpoint(attrs)

      def update_webhook_endpoint(webhook_endpoint, attrs),
        do: unquote(__MODULE__).update_webhook_endpoint(webhook_endpoint, attrs)

      def delete_webhook_endpoint(webhook_endpoint),
        do: unquote(__MODULE__).delete_webhook_endpoint(webhook_endpoint)

      def roll_webhook_endpoint_secret(webhook_endpoint, expires_at \\ DateTime.utc_now()),
        do: unquote(__MODULE__).roll_webhook_endpoint_secret(webhook_endpoint, expires_at)

      def enable_notification_type(webhook_endpoint, notification_type),
        do: unquote(__MODULE__).enable_notification_type(webhook_endpoint, notification_type)

      def disable_notification_type(webhook_endpoint, notification_type),
        do: unquote(__MODULE__).disable_notification_type(webhook_endpoint, notification_type)

      def list_webhook_notifications(opts \\ []),
        do: unquote(__MODULE__).list_webhook_notifications(opts)

      def get_webhook_notification(id, opts \\ []),
        do: unquote(__MODULE__).get_webhook_notification(id, opts)

      def get_webhook_notification!(id, opts \\ []),
        do: unquote(__MODULE__).get_webhook_notification!(id, opts)

      def list_webhook_conversations(opts \\ []),
        do: unquote(__MODULE__).list_webhook_conversations(opts)

      def get_webhook_conversation(id, opts \\ []),
        do: unquote(__MODULE__).get_webhook_conversation(id, opts)

      defoverridable CaptainHook.Behaviour
    end
  end

  @spec notify(binary, boolean, binary, map, keyword) ::
          {:ok, WebhookNotification.t()} | {:error, Ecto.Changeset.t()}
  defdelegate notify(webhook, livemode?, notification_type, data, opts \\ []), to: Notifier

  @spec send_webhook_notification(WebhookEndpoint.t(), WebhookNotification.t()) ::
          {:ok, WebhookConversation.t()} | {:error, Ecto.Changeset.t()}
  defdelegate send_webhook_notification(webhook_endpoint, webhook_notification), to: Notifier

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

  @spec get_webhook_conversation(binary, keyword) :: WebhookConversation.t() | nil
  defdelegate get_webhook_conversation(id, opts \\ []), to: WebhookConversations

  @doc false
  @spec repo :: module
  def repo() do
    Application.fetch_env!(:captain_hook, :repo)
  end
end
