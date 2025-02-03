defmodule CaptainHook.Test.FactoriesTest do
  use CaptainHook.DataCase, async: true

  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookNotifications.WebhookNotification
  alias CaptainHook.WebhookConversations.WebhookConversation

  alias CaptainHook.Test.Factories

  test "all factories can be created" do
    assert %WebhookEndpoint{} = webhook_endpoint = Factories.build(:webhook_endpoint)
    assert %WebhookNotification{} = webhook_notification = Factories.build(:webhook_notification)
    assert %WebhookConversation{} = webhook_conversation = Factories.build(:webhook_conversation)

    assert %WebhookEndpoint{id: webhook_endpoint_id} = Factories.insert!(webhook_endpoint)

    assert %WebhookNotification{id: webhook_notification_id} =
             Factories.insert!(%{webhook_notification | webhook_endpoint_id: webhook_endpoint_id})

    assert %WebhookConversation{} =
             Factories.insert!(%{
               webhook_conversation
               | webhook_notification_id: webhook_notification_id
             })
  end
end
