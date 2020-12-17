defmodule CaptainHook.Behaviour do
  # alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  # alias CaptainHook.WebhoookConversations.WebhookConversation

  # @callback notify(binary, boolean, binary, {atom, binary}, map(), keyword()) ::
  #             :ok | {:error, :no_webhook_endpoint_found | Ecto.Changeset.t()}
  # @callback notify(binary, boolean, binary, {atom, binary}, map()) ::
  #             :ok | {:error, :no_webhook_endpoint_found | Ecto.Changeset.t()}
  # @optional_callbacks notify: 6, notify: 5

  # @callback list_webhook_endpoints(binary, boolean) :: [WebhookEndpoint.t()]
  # @callback get_webhook_endpoint(binary) :: WebhookEndpoint.t()
  # @callback get_webhook_endpoint(binary, boolean) :: WebhookEndpoint.t()
  # @callback create_webhook_endpoint(map) :: WebhookEndpoint.t()
  # @callback update_webhook_endpoint(WebhookEndpoint.t(), map) :: WebhookEndpoint.t()
  # @callback delete_webhook_endpoint(WebhookEndpoint.t()) :: WebhookEndpoint.t()
  # @callback roll_webhook_endpoint_secret(WebhookEndpoint.t(), DateTime.t()) :: WebhookEndpoint.t()

  # @callback list_webhook_conversations(
  #             binary
  #             | {binary, binary, binary}
  #             | WebhookEndpoint.t(),
  #             keyword
  #           ) :: %{data: [WebhookConversation.t()], total: integer}

  # @callback get_webhook_conversation(binary()) :: WebhookConversation.t()
end
