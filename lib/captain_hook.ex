defmodule CaptainHook do
  @behaviour CaptainHook.Behaviour

  alias CaptainHook.Notifier
  alias CaptainHook.WebhookEndpoints
  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookConversations
  alias CaptainHook.WebhookConversations.WebhookConversation
  alias CaptainHook.WebhookSecrets
  alias CaptainHook.WebhookSecrets.WebhookSecret

  def notify(
        webhook,
        livemode?,
        notification_type,
        {resource_type, _resource_id} = resource,
        data,
        opts \\ []
      )
      when is_binary(webhook) and is_boolean(livemode?) and is_binary(notification_type) and
             is_atom(resource_type) and
             is_map(data) do
    webhook_endpoints = webhook |> list_webhook_endpoints(livemode?)

    if length(webhook_endpoints) == 0 do
      {:error, :no_webhook_endpoint_found}
    else
      webhook_endpoints
      |> Enum.each(&Notifier.enqueue_event(&1, notification_type, resource, data, opts))
    end
  end

  @spec list_webhook_endpoints(binary, boolean) :: [WebhookEndpoint.t()]
  defdelegate list_webhook_endpoints(webhook, livemode?), to: WebhookEndpoints

  @spec get_webhook_endpoint(binary) :: WebhookEndpoint.t()
  defdelegate get_webhook_endpoint(id), to: WebhookEndpoints

  @spec get_webhook_endpoint(binary, boolean) :: WebhookEndpoint.t()
  defdelegate get_webhook_endpoint(id, include_secret?), to: WebhookEndpoints

  @spec create_webhook_endpoint(map) :: WebhookEndpoint.t()
  defdelegate create_webhook_endpoint(attrs), to: WebhookEndpoints

  @spec update_webhook_endpoint(WebhookEndpoint.t(), map) :: WebhookEndpoint.t()
  defdelegate update_webhook_endpoint(webhook_endpoint, attrs), to: WebhookEndpoints

  @spec delete_webhook_endpoint(WebhookEndpoint.t()) :: WebhookEndpoint.t()
  def delete_webhook_endpoint(webhook_endpoint) do
    utc_now = DateTime.utc_now()
    WebhookEndpoints.delete_webhook_endpoint(webhook_endpoint, utc_now)
  end

  @spec roll_webhook_endpoint_secret(WebhookEndpoint.t(), DateTime.t()) ::
          {:ok, WebhookSecret.t()} | {:error, Ecto.Changeset.t()}
  defdelegate roll_webhook_endpoint_secret(webhook_endpoint, expires_at),
    to: WebhookSecrets,
    as: :roll

  @spec list_webhook_conversations(
          binary | {binary, binary, binary} | WebhookEndpoint.t(),
          keyword
        ) :: %{data: [WebhookConversation.t()], total: integer}
  defdelegate list_webhook_conversations(filters, opts), to: WebhookConversations

  @spec get_webhook_conversation(binary) :: WebhookConversation.t()
  defdelegate get_webhook_conversation(id), to: WebhookConversations

  def repo() do
    Application.fetch_env!(:captain_hook, :repo)
  end
end
