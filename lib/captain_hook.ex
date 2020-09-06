defmodule CaptainHook do
  @behaviour CaptainHook.Behaviour

  alias CaptainHook.WebhookEndpoints
  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookConversations
  alias CaptainHook.WebhookConversations.WebhookConversation

  @captain_hook_queue Application.get_env(:captain_hook, :queue, CaptainHook.Queue)

  @spec notify(binary(), binary(), {atom(), binary()}, map(), keyword()) ::
          :ok | {:error, :no_webhook_endpoint_found}
  def notify(webhook, action, {schema_type, schema_id}, data, opts \\ [])
      when is_binary(webhook) and is_binary(action) and is_atom(schema_type) and is_map(data) do
    webhook_endpoints =
      webhook
      |> list_webhook_endpoints()
      |> filter_webhook_endpoints(:ongoing, DateTime.utc_now())

    if length(webhook_endpoints) == 0 do
      {:error, :no_webhook_endpoint_found}
    else
      webhook_endpoints
      |> Enum.each(fn webhook_endpoint ->
        params =
          CaptainHook.DataWrapper.new(
            webhook,
            webhook_endpoint.id,
            schema_type,
            schema_id,
            data,
            opts
          )

        {:ok, _} =
          @captain_hook_queue.create_job(
            "#{webhook}_#{webhook_endpoint.id}",
            action,
            params,
            []
          )
      end)
    end
  end

  @spec list_webhook_endpoints(binary) :: [WebhookEndpoint.t()]
  defdelegate list_webhook_endpoints(webhook), to: WebhookEndpoints

  @spec filter_webhook_endpoints([WebhookEndpoint.t()], atom | [atom], DateTime.t()) :: [
          WebhookEndpoint.t()
        ]
  defdelegate filter_webhook_endpoints(webhook_endpoints, status, datetime), to: WebhookEndpoints
  @spec get_webhook_endpoint(binary, binary) :: WebhookEndpoint.t()
  defdelegate get_webhook_endpoint(webhook, id), to: WebhookEndpoints

  @spec get_webhook_endpoint!(binary, binary) :: WebhookEndpoint.t()
  defdelegate get_webhook_endpoint!(webhook, id), to: WebhookEndpoints

  @spec create_webhook_endpoint(binary, map()) :: WebhookEndpoint.t()
  defdelegate create_webhook_endpoint(webhook, attrs), to: WebhookEndpoints

  @spec update_webhook_endpoint(WebhookEndpoint.t(), map()) :: WebhookEndpoint.t()
  defdelegate update_webhook_endpoint(webhook_endpoint, attrs), to: WebhookEndpoints

  @spec delete_webhook_endpoint(WebhookEndpoint.t()) :: WebhookEndpoint.t()
  defdelegate delete_webhook_endpoint(webhook_endpoint), to: WebhookEndpoints

  @spec list_webhook_conversations(binary(), WebhookEndpoint.t() | {binary, binary}) :: [
          WebhookConversation.t()
        ]
  defdelegate list_webhook_conversations(webhook, param), to: WebhookConversations

  @spec get_webhook_conversation(binary(), binary()) :: WebhookConversation.t()
  defdelegate get_webhook_conversation(webhook, id), to: WebhookConversations

  def repo() do
    Application.fetch_env!(:captain_hook, :repo)
  end
end
