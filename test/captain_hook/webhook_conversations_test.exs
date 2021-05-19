defmodule WebhookConversations.WebhookConversationsTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  alias CaptainHook.WebhookConversations

  describe "list_webhook_conversations/1" do
    test "returns the list of webhook_conversations ordered by the sequence descending" do
      webhook_notification = insert!(:webhook_notification)

      insert!(:webhook_conversation, webhook_notification_id: webhook_notification.id)
      insert!(:webhook_conversation, webhook_notification_id: webhook_notification.id)

      assert %{data: [webhook_conversation_1, webhook_conversation_2], total: 2} =
               WebhookConversations.list_webhook_conversations()

      assert webhook_conversation_1.sequence > webhook_conversation_2.sequence
    end

    test "filters" do
      webhook_endpoint = insert!(:webhook_endpoint)

      webhook_notification =
        insert!(:webhook_notification, webhook_endpoint_id: webhook_endpoint.id)

      webhook_conversation =
        insert!(:webhook_conversation,
          webhook_notification_id: webhook_notification.id
        )

      [
        [id: webhook_conversation.id],
        [webhook_endpoint_id: webhook_notification.webhook_endpoint_id],
        [webhook_notification_id: webhook_conversation.webhook_notification_id],
        [status: webhook_conversation.status]
      ]
      |> Enum.each(fn filter ->
        assert %{data: [_webhook_conversation]} =
                 WebhookConversations.list_webhook_conversations(filters: filter)
      end)

      [
        [id: uuid()],
        [webhook_endpoint_id: uuid()],
        [webhook_notification_id: uuid()],
        [status: "status"]
      ]
      |> Enum.each(fn filter ->
        assert %{data: []} = WebhookConversations.list_webhook_conversations(filters: filter)
      end)
    end
  end

  describe "get_webhook_conversation/1" do
    test "when the webhook_conversation does not exist, returns nil" do
      assert is_nil(WebhookConversations.get_webhook_conversation(uuid()))
    end

    test "when the webhook_conversation exists, returns the webhook_conversation" do
      webhook_notification = insert!(:webhook_notification)

      webhook_conversation_factory =
        insert!(:webhook_conversation,
          webhook_notification_id: webhook_notification.id
        )

      assert webhook_conversation_factory ==
               WebhookConversations.get_webhook_conversation(webhook_conversation_factory.id)
    end
  end

  describe "create_webhook_conversation/2" do
    test "without required params, returns an :error tuple with an invalid changeset" do
      webhook_conversation_params =
        params_for(:webhook_conversation, webhook_notification_id: nil)

      assert {:error, changeset} =
               WebhookConversations.create_webhook_conversation(webhook_conversation_params)

      refute changeset.valid?
    end

    test "with valid params, returns the webhook_conversation" do
      webhook_notification = insert!(:webhook_notification)

      webhook_conversation_params =
        params_for(:webhook_conversation,
          webhook_notification_id: webhook_notification.id
        )
        |> Map.drop([:sequence])

      assert {:ok, webhook_conversation} =
               WebhookConversations.create_webhook_conversation(webhook_conversation_params)

      assert webhook_conversation.webhook_notification_id ==
               webhook_conversation_params.webhook_notification_id

      assert webhook_conversation.sequence > 0
    end
  end
end
