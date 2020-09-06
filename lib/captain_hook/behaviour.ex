defmodule CaptainHook.Behaviour do
  @callback list_webhook_endpoints(binary) :: [WebhookEndpoint.t()]
  @callback get_webhook_endpoint(binary, binary) :: WebhookEndpoint.t()
  @callback get_webhook_endpoint!(binary, binary) :: WebhookEndpoint.t()
  @callback create_webhook_endpoint(binary, map()) :: WebhookEndpoint.t()
  @callback update_webhook_endpoint(WebhookEndpoint.t(), map()) :: WebhookEndpoint.t()
  @callback delete_webhook_endpoint(WebhookEndpoint.t()) :: WebhookEndpoint.t()

  @callback list_webhook_conversations(binary(), WebhookEndpoint.t()) :: [WebhookConversation.t()]
  @callback list_webhook_conversations(binary(), {binary, binary}) :: [WebhookConversation.t()]
  @callback get_webhook_conversation(binary(), binary()) :: WebhookConversation.t()

  @callback notify(binary, binary, {atom, binary}, map(), keyword()) ::
              :ok | {:error, :no_webhook_endpoint_found | Ecto.Changeset.t()}
end
