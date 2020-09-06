defmodule WebhookConversations.WebhookConversationsTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  alias CaptainHook.WebhookConversations

  describe "list_webhook_conversations/1" do
    test "returns webhook conversation by webhook endpoint" do
      webhook_endpoint_1 = insert(:webhook_endpoint)
      webhook_endpoint_2 = insert(:webhook_endpoint)

      webhook_conversation_1 =
        insert(:webhook_conversation, webhook_endpoint_id: webhook_endpoint_1.id)

      webhook_conversation_2 =
        insert(:webhook_conversation, webhook_endpoint_id: webhook_endpoint_2.id)

      assert [] ==
               WebhookConversations.list_webhook_conversations(
                 webhook_endpoint_1.webhook,
                 webhook_endpoint_2
               )

      assert [webhook_conversation_1] ==
               WebhookConversations.list_webhook_conversations(
                 webhook_endpoint_1.webhook,
                 webhook_endpoint_1
               )

      assert [webhook_conversation_2] ==
               WebhookConversations.list_webhook_conversations(
                 webhook_endpoint_2.webhook,
                 webhook_endpoint_2
               )
    end
  end

  describe "list_webhook_conversations/2" do
    test "returns webhook conversation by parent type and id" do
      webhook_endpoint_1 = insert(:webhook_endpoint)
      webhook_endpoint_2 = insert(:webhook_endpoint)

      webhook_conversation_1 =
        insert(:webhook_conversation, webhook_endpoint_id: webhook_endpoint_1.id)

      webhook_conversation_2 =
        insert(:webhook_conversation, webhook_endpoint_id: webhook_endpoint_2.id)

      assert [] ==
               WebhookConversations.list_webhook_conversations(
                 webhook_endpoint_2.webhook,
                 {webhook_conversation_1.schema_type, webhook_conversation_1.schema_id}
               )

      assert [webhook_conversation_1] ==
               WebhookConversations.list_webhook_conversations(
                 webhook_endpoint_1.webhook,
                 {webhook_conversation_1.schema_type, webhook_conversation_1.schema_id}
               )

      assert [webhook_conversation_2] ==
               WebhookConversations.list_webhook_conversations(
                 webhook_endpoint_2.webhook,
                 {webhook_conversation_2.schema_type, webhook_conversation_2.schema_id}
               )
    end
  end

  describe "get_webhook_conversation/1" do
    test "when the webhook_conversation does not exist, returns nil" do
      assert is_nil(
               WebhookConversations.get_webhook_conversation(
                 "webhook",
                 CaptainHook.Factory.uuid()
               )
             )
    end

    test "when the webhook_conversation does not belong to the webhook requestion, returns nil" do
      webhook_conversation_factory = insert(:webhook_conversation)

      assert is_nil(
               WebhookConversations.get_webhook_conversation(
                 "webhook",
                 webhook_conversation_factory.id
               )
             )
    end

    test "when the webhook_conversation exists, returns the webhook_conversation" do
      webhook_endpoint = insert(:webhook_endpoint)

      webhook_conversation_factory =
        insert(:webhook_conversation, webhook_endpoint_id: webhook_endpoint.id)

      assert webhook_conversation_factory ==
               WebhookConversations.get_webhook_conversation(
                 webhook_endpoint.webhook,
                 webhook_conversation_factory.id
               )
    end
  end

  describe "create_webhook_conversation/2" do
    test "without required params, returns an :error tuple with an invalid changeset" do
      webhook_endpoint = build(:webhook_endpoint, id: CaptainHook.Factory.uuid())

      webhook_conversation_params =
        params_for(:webhook_conversation, webhook_endpoint_id: webhook_endpoint.id)

      assert {:error, changeset} =
               WebhookConversations.create_webhook_conversation(
                 webhook_endpoint,
                 webhook_conversation_params
               )

      refute changeset.valid?
    end

    test "with valid params, returns the webhook_endpoint" do
      webhook_endpoint = insert(:webhook_endpoint)
      webhook_conversation_params = params_for(:webhook_conversation)

      assert {:ok, webhook_conversation} =
               WebhookConversations.create_webhook_conversation(
                 webhook_endpoint,
                 webhook_conversation_params
               )

      assert webhook_conversation.webhook_endpoint_id == webhook_endpoint.id
    end
  end
end
