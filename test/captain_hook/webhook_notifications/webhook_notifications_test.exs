defmodule CaptainHook.WebhookNotificationsTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  alias CaptainHook.WebhookNotifications
  alias CaptainHook.WebhookNotifications.WebhookNotification

  describe "list_webhook_notifications/1" do
    test "returns the list of webhook_notifications ordered by the sequence descending" do
      insert!(:webhook_notification)
      insert!(:webhook_notification)

      assert %{data: [webhook_notification_1, webhook_notification_2], total: 2} =
               WebhookNotifications.list_webhook_notifications()

      assert webhook_notification_1.sequence > webhook_notification_2.sequence
    end

    test "filters" do
      webhook_notification = insert!(:webhook_notification)

      [
        [id: webhook_notification.id],
        [livemode: webhook_notification.livemode],
        [resource_id: webhook_notification.resource_id],
        [resource_type: webhook_notification.resource_type],
        [type: webhook_notification.type],
        [webhook: webhook_notification.webhook]
      ]
      |> Enum.each(fn filter ->
        assert %{data: [_webhook_notification]} =
                 WebhookNotifications.list_webhook_notifications(filters: filter)
      end)

      [
        [id: uuid()],
        [livemode: !webhook_notification.livemode],
        [resource_id: "resource_id"],
        [resource_type: "resource_type"],
        [type: "type"],
        [webhook: "webhook"]
      ]
      |> Enum.each(fn filter ->
        assert %{data: []} = WebhookNotifications.list_webhook_notifications(filters: filter)
      end)
    end
  end

  describe "get_webhook_notification/2" do
    test "when then webhook_notification exists, returns the webhook_notification" do
      webhook_notification_factory = insert!(:webhook_notification)

      webhook_notification =
        WebhookNotifications.get_webhook_notification(webhook_notification_factory.id)

      assert %WebhookNotification{} = webhook_notification
      assert webhook_notification.id == webhook_notification_factory.id
    end

    test "when the webhook_notification does not exist, returns nil" do
      assert is_nil(WebhookNotifications.get_webhook_notification(uuid()))
    end
  end

  describe "get_webhook_notification!/2" do
    test "when then webhook_notification exists, returns the webhook_notification" do
      webhook_notification_factory = insert!(:webhook_notification)

      assert %WebhookNotification{} =
               WebhookNotifications.get_webhook_notification!(webhook_notification_factory.id)
    end

    test "when the webhook_notification does not exist, raises a Ecto.NoResultsError" do
      assert_raise Ecto.NoResultsError, fn ->
        WebhookNotifications.get_webhook_notification!(uuid())
      end
    end
  end

  describe "create_webhook_notification/2" do
    test "without required params, returns an :error tuple with an invalid changeset" do
      webhook_notification_params = params_for(:webhook_notification, webhook: nil)

      assert {:error, changeset} =
               WebhookNotifications.create_webhook_notification(webhook_notification_params)

      refute changeset.valid?
    end

    test "with valid params, returns the webhook_notification" do
      webhook_notification_params = params_for(:webhook_notification) |> Map.drop([:sequence])

      assert {:ok, %WebhookNotification{} = webhook_notification} =
               WebhookNotifications.create_webhook_notification(webhook_notification_params)

      assert webhook_notification.data == webhook_notification_params.data
      assert webhook_notification.livemode == webhook_notification_params.livemode
      assert webhook_notification.resource_id == webhook_notification_params.resource_id
      assert webhook_notification.resource_type == webhook_notification_params.resource_type
      assert webhook_notification.type == webhook_notification_params.type
      assert webhook_notification.webhook == webhook_notification_params.webhook
      assert webhook_notification.sequence > 0
    end
  end
end
