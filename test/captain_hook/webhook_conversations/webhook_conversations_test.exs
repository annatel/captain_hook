defmodule WebhookConversations.WebhookConversationsTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  alias CaptainHook.WebhookConversations

  describe "list_webhook_conversations/3 - by webhook_endpoint" do
    test "returns the webhook_conversations according to the webhook_endpoint and the webhook name" do
      webhook_endpoint_1 = insert!(:webhook_endpoint)
      webhook_endpoint_2 = insert!(:webhook_endpoint)

      webhook_conversation_1 =
        insert!(:webhook_conversation, webhook_endpoint_id: webhook_endpoint_1.id)

      assert %{data: [], total: 0} =
               WebhookConversations.list_webhook_conversations(
                 webhook_endpoint_2.webhook,
                 webhook_endpoint_1
               )

      assert %{data: [^webhook_conversation_1], total: 1} =
               WebhookConversations.list_webhook_conversations(
                 webhook_endpoint_1.webhook,
                 webhook_endpoint_1
               )
    end
  end

  describe "list_webhook_conversations/3 - by request_id" do
    test "returns the webhook_conversations according to the request_id and the webhook name" do
      webhook_endpoint_1 = insert!(:webhook_endpoint)
      webhook_endpoint_2 = insert!(:webhook_endpoint)

      webhook_conversation_1 =
        insert!(:webhook_conversation, webhook_endpoint_id: webhook_endpoint_1.id)

      assert %{data: [], total: 0} ==
               WebhookConversations.list_webhook_conversations(
                 webhook_endpoint_2.webhook,
                 webhook_conversation_1.request_id
               )

      assert %{data: [^webhook_conversation_1], total: 1} =
               WebhookConversations.list_webhook_conversations(
                 webhook_endpoint_1.webhook,
                 webhook_conversation_1.request_id
               )
    end
  end

  describe "list_webhook_conversations/3 - by resource_type and resource_id" do
    test "returns the webhook_conversations according to the request_id and the webhook name" do
      webhook_endpoint_1 = insert!(:webhook_endpoint)
      webhook_endpoint_2 = insert!(:webhook_endpoint)

      webhook_conversation_1 =
        insert!(:webhook_conversation, webhook_endpoint_id: webhook_endpoint_1.id)

      assert %{data: [], total: 0} ==
               WebhookConversations.list_webhook_conversations(
                 webhook_endpoint_2.webhook,
                 {webhook_conversation_1.resource_type, webhook_conversation_1.resource_id}
               )

      assert %{data: [^webhook_conversation_1], total: 1} =
               WebhookConversations.list_webhook_conversations(
                 webhook_endpoint_1.webhook,
                 {webhook_conversation_1.resource_type, webhook_conversation_1.resource_id}
               )
    end
  end

  describe "list_webhook_conversation/3 - pagination" do
    test "returns num of webhook_conversation according to the pagination params and ordered by the sequence" do
      webhook_endpoint = insert!(:webhook_endpoint)

      resource_type = "resource_type"
      resource_id = "resource_id"

      webhook_conversation_1 =
        insert!(:webhook_conversation,
          webhook_endpoint_id: webhook_endpoint.id,
          resource_type: resource_type,
          resource_id: resource_id
        )

      webhook_conversation_2 =
        insert!(:webhook_conversation,
          webhook_endpoint_id: webhook_endpoint.id,
          resource_type: resource_type,
          resource_id: resource_id
        )

      _webhook_conversation_3 =
        insert!(:webhook_conversation,
          webhook_endpoint_id: webhook_endpoint.id
        )

      assert %{data: [^webhook_conversation_1, ^webhook_conversation_2], total: 2} =
               WebhookConversations.list_webhook_conversations(
                 webhook_endpoint.webhook,
                 [resource_type: resource_type, resource_id: resource_id],
                 %{page: 1, opts: [per_page: 100]}
               )

      assert %{data: [^webhook_conversation_1], total: 2} =
               WebhookConversations.list_webhook_conversations(
                 webhook_endpoint.webhook,
                 [resource_type: resource_type, resource_id: resource_id],
                 %{page: 1, opts: [per_page: 1]}
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
      webhook_conversation_factory = insert!(:webhook_conversation)

      assert is_nil(
               WebhookConversations.get_webhook_conversation(
                 "webhook",
                 webhook_conversation_factory.id
               )
             )
    end

    test "when the webhook_conversation exists, returns the webhook_conversation" do
      webhook_endpoint = insert!(:webhook_endpoint)

      webhook_conversation_factory =
        insert!(:webhook_conversation, webhook_endpoint_id: webhook_endpoint.id)

      assert webhook_conversation_factory ==
               WebhookConversations.get_webhook_conversation(
                 webhook_endpoint.webhook,
                 webhook_conversation_factory.id
               )
    end
  end

  describe "create_webhook_conversation/2" do
    test "without required params, returns an :error tuple with an invalid changeset" do
      webhook_endpoint = build(:webhook_endpoint, id: uuid())

      webhook_conversation_params = params_for(:webhook_conversation, webhook_endpoint_id: nil)

      assert {:error, changeset} =
               WebhookConversations.create_webhook_conversation(
                 webhook_endpoint,
                 webhook_conversation_params
               )

      refute changeset.valid?
    end

    test "with valid params, returns the webhook_endpoint" do
      webhook_endpoint = insert!(:webhook_endpoint)
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
