defmodule CaptainHook.Test.FactoriesTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookNotifications.WebhookNotification
  alias CaptainHook.WebhookConversations.WebhookConversation

  alias CaptainHook.Test.Factories

  test "all factories can be created" do
    assert %WebhookEndpoint{} = webhook_endpoint = Factories.build(:webhook_endpoint)
    assert %WebhookNotification{} = webhook_notification = Factories.build(:webhook_notification)
    assert %WebhookConversation{} = webhook_conversation = Factories.build(:webhook_conversation)

    assert %WebhookEndpoint{id: webhook_endpoint_id} = insert!(webhook_endpoint)

    assert %WebhookNotification{id: webhook_notification_id} =
             insert!(%{webhook_notification | webhook_endpoint_id: webhook_endpoint_id})

    assert %WebhookConversation{} =
             insert!(%{webhook_conversation | webhook_notification_id: webhook_notification_id})
  end
end
