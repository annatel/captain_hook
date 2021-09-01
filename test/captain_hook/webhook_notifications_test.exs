defmodule CaptainHook.WebhookNotificationsTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  alias CaptainHook.WebhookNotifications
  alias CaptainHook.WebhookNotifications.WebhookNotification

  describe "list_webhook_notifications/1" do
    test "list_webhook_notifications" do
      %{id: id_1} = insert!(:webhook_notification, sequence: 1)
      %{id: id_2} = insert!(:webhook_notification, sequence: 2)

      assert [%{id: ^id_2}, %{id: ^id_1}] = WebhookNotifications.list_webhook_notifications()
      assert [%{id: ^id_1}] = WebhookNotifications.list_webhook_notifications(filters: [id: id_1])
    end
  end

  describe "paginate_webhook_notifications/1" do
    test "returns the list of webhook_notifications ordered by the sequence descending" do
      %{id: id1} = insert!(:webhook_notification, sequence: 1)
      %{id: id2} = insert!(:webhook_notification, sequence: 2)

      assert %{
               data: [%{id: ^id2} = webhook_notification_2, %{id: ^id1} = webhook_notification_1],
               page_number: 1,
               page_size: 100,
               total: 2
             } = WebhookNotifications.paginate_webhook_notifications()

      assert webhook_notification_2.sequence > webhook_notification_1.sequence

      assert %{data: [], page_number: 2, page_size: 100, total: 2} =
               WebhookNotifications.paginate_webhook_notifications(100, 2)
    end

    test "filters" do
      webhook_notification = insert!(:webhook_notification)

      [
        [id: webhook_notification.id],
        [has_succeeded: false],
        [ref: webhook_notification.ref],
        [resource_id: webhook_notification.resource_id],
        [resource_object: webhook_notification.resource_object],
        [webhook_endpoint_id: webhook_notification.webhook_endpoint_id]
      ]
      |> Enum.each(fn filter ->
        assert %{data: [_webhook_notification]} =
                 WebhookNotifications.paginate_webhook_notifications(100, 1, filters: filter)
      end)

      [
        [id: shortcode_uuid("wn")],
        [has_succeeded: true],
        [ref: "ref"],
        [resource_id: "resource_id"],
        [resource_object: "resource_object"],
        [webhook_endpoint_id: shortcode_uuid("we")]
      ]
      |> Enum.each(fn filter ->
        assert %{data: []} =
                 WebhookNotifications.paginate_webhook_notifications(100, 1, filters: filter)
      end)
    end

    test "includes" do
      insert!(:webhook_notification)

      assert %{data: [webhook_notification]} =
               WebhookNotifications.paginate_webhook_notifications()

      refute Ecto.assoc_loaded?(webhook_notification.webhook_endpoint)

      assert %{data: [webhook_notification]} =
               WebhookNotifications.paginate_webhook_notifications(100, 1,
                 includes: [:webhook_endpoint]
               )

      assert Ecto.assoc_loaded?(webhook_notification.webhook_endpoint)
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
      assert is_nil(WebhookNotifications.get_webhook_notification(shortcode_uuid("wn")))
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
      assert webhook_notification.ref == webhook_notification_params.ref

      assert webhook_notification.webhook_endpoint_id ==
               webhook_notification_params.webhook_endpoint_id

      assert webhook_notification.sequence > 0
    end
  end
end
