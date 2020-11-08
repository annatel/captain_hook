defmodule CaptainHook do
  @behaviour CaptainHook.Behaviour

  alias CaptainHook.Sender
  alias CaptainHook.WebhookEndpoints
  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookConversations
  alias CaptainHook.WebhookConversations.WebhookConversation
  alias CaptainHook.WebhookSecrets
  alias CaptainHook.WebhookSecrets.WebhookSecret

  @spec notify(binary(), binary(), {atom(), binary()}, map(), keyword()) ::
          :ok | {:error, :no_webhook_endpoint_found}
  def notify(
        webhook,
        livemode?,
        notification_type,
        {resource_type, _resource_id} = resource,
        data,
        opts \\ []
      )
      when is_binary(webhook) is_boolean(livemode) and is_binary(notification_type) and is_atom(resource_type) and
             is_map(data) do
    webhook_endpoints = webhook |> list_webhook_endpoints(livemode?)

    if length(webhook_endpoints) == 0 do
      {:error, :no_webhook_endpoint_found}
    else
      webhook_endpoints
      |> Enum.each(&Sender.enqueue_event(&1, notification_type, resource, data, opts))
    end
  end

  @spec list_webhook_endpoints(binary, boolean) :: [WebhookEndpoint.t()]
  defdelegate list_webhook_endpoints(webhook, livemode?), to: WebhookEndpoints

  @spec get_webhook_endpoint(binary, binary) :: WebhookEndpoint.t()
  defdelegate get_webhook_endpoint(webhook, id), to: WebhookEndpoints

  @spec get_webhook_endpoint(binary, binary, boolean) :: WebhookEndpoint.t()
  defdelegate get_webhook_endpoint(webhook, id, include_secret?), to: WebhookEndpoints

  @spec create_webhook_endpoint(binary, map()) :: WebhookEndpoint.t()
  defdelegate create_webhook_endpoint(webhook, attrs), to: WebhookEndpoints

  @spec update_webhook_endpoint(WebhookEndpoint.t(), map()) :: WebhookEndpoint.t()
  defdelegate update_webhook_endpoint(webhook_endpoint, attrs), to: WebhookEndpoints

  @spec delete_webhook_endpoint(WebhookEndpoint.t()) :: WebhookEndpoint.t()
  defdelegate delete_webhook_endpoint(webhook_endpoint), to: WebhookEndpoints

  @spec roll_webhook_endpoint_secret(WebhookEndpoint.t(), DateTime.t()) ::
          {:ok, WebhookSecret.t()} | {:error, Ecto.Changeset.t()}
  defdelegate roll_webhook_endpoint_secret(webhook_endpoint, expires_at),
    to: WebhookSecrets,
    as: :roll

  @spec list_webhook_conversations(
          binary,
          binary | {binary, binary} | WebhookEndpoint.t(),
          %{opts: keyword, page: number}
        ) :: %{data: [WebhookConversation.t()], total: integer}
  defdelegate list_webhook_conversations(webhook, filter, pagination), to: WebhookConversations

  @spec get_webhook_conversation(binary(), binary()) :: WebhookConversation.t()
  defdelegate get_webhook_conversation(webhook, id), to: WebhookConversations

  def repo() do
    Application.fetch_env!(:captain_hook, :repo)
  end
end
