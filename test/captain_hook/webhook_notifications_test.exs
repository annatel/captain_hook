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
        [resource_id: webhook_notification.resource_id],
        [resource_object: webhook_notification.resource_object],
        [type: webhook_notification.type],
        [webhook_endpoint_id: webhook_notification.webhook_endpoint_id]
      ]
      |> Enum.each(fn filter ->
        assert %{data: [_webhook_notification]} =
                 WebhookNotifications.list_webhook_notifications(filters: filter)
      end)

      [
        [id: uuid()],
        [resource_id: "resource_id"],
        [resource_object: "resource_object"],
        [type: "type"],
        [webhook_endpoint_id: uuid()]
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
      webhook_notification_params = params_for(:webhook_notification, webhook_endpoint_id: nil)

      assert {:error, changeset} =
               WebhookNotifications.create_webhook_notification(webhook_notification_params)

      refute changeset.valid?
    end

    test "with valid params, returns the webhook_notification" do
      webhook_notification_params = params_for(:webhook_notification) |> Map.drop([:sequence])

      assert {:ok, %WebhookNotification{} = webhook_notification} =
               WebhookNotifications.create_webhook_notification(webhook_notification_params)

      assert webhook_notification.data == webhook_notification_params.data

      assert webhook_notification.resource_id == webhook_notification_params.resource_id
      assert webhook_notification.resource_object == webhook_notification_params.resource_object
      assert webhook_notification.type == webhook_notification_params.type

      assert webhook_notification.webhook_endpoint_id ==
               webhook_notification_params.webhook_endpoint_id

      assert webhook_notification.sequence > 0
    end
  end
end