defmodule CaptainHook.Behaviour do
  @callback list_webhook_endpoints(binary) :: [WebhookEndpoint.t()]
  @callback get_webhook_endpoint(binary, binary) :: WebhookEndpoint.t()
  @callback get_webhook_endpoint!(binary, binary) :: WebhookEndpoint.t()
  @callback create_webhook_endpoint(binary, map()) :: WebhookEndpoint.t()
  @callback update_webhook_endpoint(WebhookEndpoint.t(), map()) :: WebhookEndpoint.t()
  @callback delete_webhook_endpoint(WebhookEndpoint.t()) :: WebhookEndpoint.t()

  @callback list_webhook_conversations(
              binary,
              binary | {binary, binary} | CaptainHook.WebhookEndpoints.WebhookEndpoint.t(),
              %{opts: keyword, page: number}
            ) :: %{items: [WebhookConversation.t()], total: integer}
  @callback list_webhook_conversations(
              binary,
              binary | {binary, binary} | CaptainHook.WebhookEndpoints.WebhookEndpoint.t()
            ) :: %{items: [WebhookConversation.t()], total: integer}
  @optional_callbacks list_webhook_conversations: 2, list_webhook_conversations: 3

  @callback get_webhook_conversation(binary(), binary()) :: WebhookConversation.t()

  @callback notify(binary, binary, {atom, binary}, map(), keyword()) ::
              :ok | {:error, :no_webhook_endpoint_found | Ecto.Changeset.t()}
  @callback notify(binary, binary, {atom, binary}, map()) ::
              :ok | {:error, :no_webhook_endpoint_found | Ecto.Changeset.t()}
  @optional_callbacks notify: 5, notify: 4
end
