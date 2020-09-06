defmodule CaptainHook.WebhookConversations do
  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookConversations.{WebhookConversation, WebhookConversationQueryable}

  @spec list_webhook_conversations(binary(), WebhookEndpoint.t() | {binary, binary}) :: [
          WebhookConversation.t()
        ]
  def list_webhook_conversations(webhook, %WebhookEndpoint{id: webhook_endpoint_id})
      when is_binary(webhook) do
    WebhookConversationQueryable.queryable()
    |> WebhookConversationQueryable.search(webhook)
    |> WebhookConversationQueryable.filter(webhook_endpoint_id: webhook_endpoint_id)
    |> CaptainHook.repo().all()
  end

  def list_webhook_conversations(webhook, {schema_type, schema_id})
      when is_binary(webhook) and is_binary(schema_type) and is_binary(schema_id) do
    WebhookConversationQueryable.queryable()
    |> WebhookConversationQueryable.search(webhook)
    |> WebhookConversationQueryable.filter(schema_type: schema_type, schema_id: schema_id)
    |> CaptainHook.repo().all()
  end

  @spec get_webhook_conversation(binary(), binary()) :: WebhookConversation.t()
  def get_webhook_conversation(webhook, id) when is_binary(webhook) and is_binary(id) do
    WebhookConversationQueryable.queryable()
    |> WebhookConversationQueryable.search(webhook)
    |> WebhookConversationQueryable.filter(id: id)
    |> CaptainHook.repo().one()
  end

  @spec create_webhook_conversation(WebhookEndpoint.t(), map()) :: WebhookConversation.t()
  def create_webhook_conversation(%WebhookEndpoint{id: webhook_endpoint_id}, attrs)
      when is_map(attrs) do
    attrs = attrs |> Map.put(:webhook_endpoint_id, webhook_endpoint_id)

    %WebhookConversation{}
    |> WebhookConversation.changeset(attrs)
    |> CaptainHook.repo().insert()
  end

  @spec conversation_succeeded?(WebhookConversation.t()) :: boolean
  def conversation_succeeded?(%WebhookConversation{status: status}) do
    status == WebhookConversation.status().success
  end
end
