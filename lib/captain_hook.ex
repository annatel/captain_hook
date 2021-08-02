defmodule CaptainHook do
  alias CaptainHook.Notifier
  alias CaptainHook.WebhookEndpoints
  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookNotifications
  alias CaptainHook.WebhookNotifications.WebhookNotification
  alias CaptainHook.WebhookConversations
  alias CaptainHook.WebhookConversations.WebhookConversation

  defmacro __using__(_opts) do
    quote do
      def notify(owner_id, livemode?, notification_type, data, opts \\ []),
        do: unquote(__MODULE__).notify(owner_id, livemode?, notification_type, data, opts)

      def async_notify(owner_id, livemode?, notification_type, data, opts \\ []),
        do: unquote(__MODULE__).async_notify(owner_id, livemode?, notification_type, data, opts)

      @spec send_webhook_notification!(WebhookNotification.t()) :: map
      def send_webhook_notification!(webhook_notification),
        do: unquote(__MODULE__).send_webhook_notification!(webhook_notification)

      @spec paginate_webhook_endpoints(non_neg_integer, non_neg_integer, keyword) :: %{
              data: [WebhookEndpoint.t()],
              page_number: non_neg_integer,
              page_size: non_neg_integer,
              total: integer
            }
      def paginate_webhook_endpoints(page_size, page_number, opts \\ []),
        do: unquote(__MODULE__).paginate_webhook_endpoints(page_size, page_number, opts)

      @spec get_webhook_endpoint(binary, keyword) :: WebhookEndpoint.t() | nil
      def get_webhook_endpoint(id, opts \\ []),
        do: unquote(__MODULE__).get_webhook_endpoint(id, opts)

      @spec get_webhook_endpoint!(binary, keyword) :: WebhookEndpoint.t()
      def get_webhook_endpoint!(id, opts \\ []),
        do: unquote(__MODULE__).get_webhook_endpoint!(id, opts)

      @spec create_webhook_endpoint(map()) ::
              {:ok, WebhookEndpoint.t()} | {:error, Ecto.Changeset.t()}
      def create_webhook_endpoint(attrs), do: unquote(__MODULE__).create_webhook_endpoint(attrs)

      @spec update_webhook_endpoint(WebhookEndpoint.t(), map()) ::
              {:ok, WebhookEndpoint.t()} | {:error, Ecto.Changeset.t()}
      def update_webhook_endpoint(webhook_endpoint, attrs),
        do: unquote(__MODULE__).update_webhook_endpoint(webhook_endpoint, attrs)

      @spec delete_webhook_endpoint(WebhookEndpoint.t()) ::
              {:ok, WebhookEndpoint.t()} | {:error, Ecto.Changeset.t()}
      def delete_webhook_endpoint(webhook_endpoint),
        do: unquote(__MODULE__).delete_webhook_endpoint(webhook_endpoint)

      @spec roll_webhook_endpoint_secret(WebhookEndpoint.t(), DateTime.t()) ::
              {:ok, Secrets.WebhookEndpointSecret.t()} | {:error, Ecto.Changeset.t()}
      def roll_webhook_endpoint_secret(webhook_endpoint, expires_at \\ DateTime.utc_now()),
        do: unquote(__MODULE__).roll_webhook_endpoint_secret(webhook_endpoint, expires_at)

      @spec enable_notification_type(WebhookEndpoint.t(), binary | [binary]) ::
              {:ok, WebhookEndpoint.t()} | {:error, Ecto.Changeset.t()}
      def enable_notification_type(webhook_endpoint, notification_type),
        do: unquote(__MODULE__).enable_notification_type(webhook_endpoint, notification_type)

      @spec disable_event_type(WebhookEndpoint.t(), binary | [binary]) ::
              {:ok, WebhookEndpoint.t()} | {:error, Ecto.Changeset.t()}
      def disable_notification_type(webhook_endpoint, notification_type),
        do: unquote(__MODULE__).disable_notification_type(webhook_endpoint, notification_type)

      @spec paginate_webhook_notifications(non_neg_integer, non_neg_integer, keyword) :: %{
              data: [WebhookNotification.t()],
              page_number: non_neg_integer,
              page_size: non_neg_integer,
              total: integer
            }
      def paginate_webhook_notifications(page_size, page_number, opts \\ []),
        do: unquote(__MODULE__).list_webhook_notifications(page_size, page_number, opts)

      @spec get_webhook_notification(binary, keyword) :: WebhookNotification.t() | nil
      def get_webhook_notification(id, opts \\ []),
        do: unquote(__MODULE__).get_webhook_notification(id, opts)

      @spec get_webhook_notification!(binary, keyword) :: WebhookNotification.t()
      def get_webhook_notification!(id, opts \\ []),
        do: unquote(__MODULE__).get_webhook_notification!(id, opts)

      @spec paginate_webhook_conversations(non_neg_integer, non_neg_integer, keyword) :: %{
              data: [WebhookConversation.t()],
              page_number: non_neg_integer,
              page_size: non_neg_integer,
              total: integer
            }
      def paginate_webhook_conversations(page_size, page_number, opts \\ []),
        do: unquote(__MODULE__).paginate_webhook_conversations(page_size, page_number, opts)

      @spec get_webhook_conversation(binary, keyword) :: WebhookConversation.t() | nil
      def get_webhook_conversation(id, opts \\ []),
        do: unquote(__MODULE__).get_webhook_conversation(id, opts)

      @spec failure_report_email_subject(WebhookNotification.t(), WebhookConversation.t()) ::
              binary
      def failure_report_email_subject(webhook_notification, webhook_conversation),
        do:
          unquote(__MODULE__).failure_report_email_subject(
            webhook_notification,
            webhook_conversation
          )

      @spec failure_report_email_html_body(
              WebhookNotification.t(),
              WebhookConversation.t(),
              binary
            ) ::
              binary
      def failure_report_email_html_body(
            webhook_notification,
            webhook_conversation,
            webhook_conversations_url \\ nil
          ),
          do:
            unquote(__MODULE__).failure_report_email_html_body(
              webhook_notification,
              webhook_conversation,
              webhook_conversations_url
            )
    end
  end

  @spec notify(binary | [binary], boolean, binary, map, keyword) ::
          {:ok, [WebhookNotification.t()]} | {:error, Ecto.Changeset.t()}
  defdelegate notify(owner_id, livemode?, notification_type, data, opts \\ []), to: Notifier

  @spec async_notify(binary | [binary], boolean, binary, map, keyword) ::
          {:ok, [WebhookNotification.t()]} | {:error, Ecto.Changeset.t()}
  defdelegate async_notify(owner_id, livemode?, notification_type, data, opts \\ []),
    to: Notifier

  @spec send_webhook_notification!(WebhookNotification.t()) ::
          %{
            webhook_conversation: WebhookConversation.t(),
            webhook_notification: WebhookNotification.t()
          }
  defdelegate send_webhook_notification!(webhook_notification), to: Notifier

  @spec paginate_webhook_endpoints(non_neg_integer, non_neg_integer, keyword) :: %{
          data: [WebhookEndpoint.t()],
          page_number: non_neg_integer,
          page_size: non_neg_integer,
          total: integer
        }
  defdelegate paginate_webhook_endpoints(page_size, page_number, opts \\ []), to: WebhookEndpoints

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

  @spec paginate_webhook_notifications(non_neg_integer, non_neg_integer, keyword) :: %{
          data: [WebhookNotification.t()],
          page_number: non_neg_integer,
          page_size: non_neg_integer,
          total: integer
        }
  defdelegate paginate_webhook_notifications(page_size, page_number, opts \\ []),
    to: WebhookNotifications

  @spec get_webhook_notification(binary, keyword) :: WebhookNotification.t() | nil
  defdelegate get_webhook_notification(id, opts \\ []), to: WebhookNotifications

  @spec get_webhook_notification!(binary, keyword) :: WebhookNotification.t()
  defdelegate get_webhook_notification!(id, opts \\ []), to: WebhookNotifications

  @spec paginate_webhook_conversations(non_neg_integer, non_neg_integer, keyword) :: %{
          data: [WebhookConversation.t()],
          page_number: non_neg_integer,
          page_size: non_neg_integer,
          total: integer
        }
  defdelegate paginate_webhook_conversations(page_size, page_number, opts \\ []),
    to: WebhookConversations

  @spec get_webhook_conversation(binary, keyword) :: WebhookConversation.t() | nil
  defdelegate get_webhook_conversation(id, opts \\ []), to: WebhookConversations

  @doc false
  @spec failure_report_email_subject(WebhookNotification.t()) :: binary
  def failure_report_email_subject(%WebhookNotification{webhook_endpoint_id: webhook_endpoint_id}) do
    "A failure happens on the webhook endpoint #{webhook_endpoint_id}."
  end

  @spec failure_report_email_html_body(
          CaptainHook.WebhookNotifications.WebhookNotification.t(),
          CaptainHook.WebhookConversations.WebhookConversation.t(),
          binary
        ) :: binary
  @doc false
  def failure_report_email_html_body(
        %WebhookNotification{webhook_endpoint_id: webhook_endpoint_id},
        %WebhookConversation{
          client_error_message: client_error_message,
          http_status: http_status,
          request_url: request_url,
          request_body: request_body,
          response_body: response_body
        },
        webhook_conversations_url \\ nil
      ) do
    request_body = Jason.decode!(request_body) |> Jason.encode!(pretty: true)

    """
    Hi,<br/>
    <br/>
    Here is a report about a webhook failure about the webhook endpoint #{maybe_add_link(webhook_conversations_url, webhook_endpoint_id)}<br/>
    <br/>
    <b>Request url:</b> #{request_url}<br/>
    <b>HTTP status:</b> #{http_status}<br/>#{client_error_message_text(client_error_message)}
    <br/>
    <br/>
    <b>Response:</b> #{response_body}<br/>
    <b>Request:</b>
    <pre>
    #{request_body}
    </pre>
    <br/>
    <b>Please, fix the failure in order to unlock the flow of the reports.</b>
    <br/>
    """
  end

  defp maybe_add_link(nil, webhook_endpoint_id), do: webhook_endpoint_id

  defp maybe_add_link(webhook_conversations_url, webhook_endpoint_id)
       when is_binary(webhook_conversations_url) do
    "<a href='#{webhook_conversations_url}'>#{webhook_endpoint_id}</a>"
  end

  defp client_error_message_text(nil), do: ""

  defp client_error_message_text(client_error_message) when is_binary(client_error_message),
    do: "<b>Client error message (if any):</b> #{client_error_message}"

  @spec webhook_conversations_url(binary) :: nil | binary
  def webhook_conversations_url(webhook_endpoint_id) when is_binary(webhook_endpoint_id) do
    nil
  end

  @doc false
  @spec repo :: module
  def repo() do
    Application.fetch_env!(:captain_hook, :repo)
  end

  @doc false
  @spec notification_type_separator :: binary
  def notification_type_separator() do
    Application.fetch_env!(:captain_hook, :notification_type_separator)
  end

  @doc false
  @spec notification_type_wildcard :: binary
  def notification_type_wildcard() do
    Application.fetch_env!(:captain_hook, :notification_type_wildcard)
  end

  @spec owner_id_field(atom) :: tuple
  def owner_id_field(:migration) do
    Application.get_env(:captain_hook, :owner_id_field, migration: {:owner_id, :binary_id})[
      :migration
    ]
  end

  def owner_id_field(:schema) do
    Application.get_env(:captain_hook, :owner_id_field, schema: {:owner_id, :binary_id, []})[
      :schema
    ]
  end
end
