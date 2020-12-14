defmodule CaptainHook.WebhookNotificationsTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  alias CaptainHook.WebhookNotifications

  @datetime_1 DateTime.from_naive!(~N[2018-05-24 12:27:48], "Etc/UTC")
  @datetime_2 DateTime.from_naive!(~N[2018-06-24 12:27:48], "Etc/UTC")

  describe "list_webhook_notifications/1" do
    test "returns the list of webhook_notifications ordered by their started_at ascending" do
      %{id: webhook_notification_1_id} = insert!(:webhook_notification, started_at: @datetime_1)

      %{id: webhook_notification_2_id} = insert!(:webhook_notification, started_at: @datetime_2)

      assert [%{id: ^webhook_notification_1_id}, %{id: ^webhook_notification_2_id}] =
               WebhookNotifications.list_webhook_notifications()
    end

    test "filters" do
      utc_now = utc_now()

      webhook_notification =
        insert!(:webhook_notification,
          started_at: utc_now,
          ended_at: DateTime.add(utc_now, 3600, :second)
        )

      [
        [id: webhook_notification.id],
        [webhook: webhook_notification.webhook],
        [livemode: webhook_notification.livemode],
        [ongoing_at: utc_now]
      ]
      |> Enum.each(fn filter ->
        assert [_webhook_notification] =
                 WebhookNotifications.list_webhook_notifications(filters: filter)
      end)

      [
        [id: uuid()],
        [webhook: "webhook"],
        [livemode: !webhook_notification.livemode],
        [ended_at: DateTime.add(utc_now, -3600, :second)],
        [scheduled_at: DateTime.add(utc_now, 7200, :second)]
      ]
      |> Enum.each(fn filter ->
        assert [] = WebhookNotifications.list_webhook_notifications(filters: filter)
      end)
    end
  end

  describe "get_webhook_notification/2" do
    test "when then webhook_notification exists, returns the webhook_notification" do
      webhook_notification_factory = insert!(:webhook_notification)

      webhook_notification =
        WebhookNotifications.get_webhook_notification(webhook_notification_factory.id)

      assert %WebhookNotifications.WebhookNotification{} = webhook_notification
      assert webhook_notification.webhook == webhook_notification_factory.webhook
      assert webhook_notification.id == webhook_notification_factory.id
      assert is_nil(webhook_notification.secret)
    end

    test "when the webhook_notification does not exist, returns nil" do
      assert is_nil(WebhookNotifications.get_webhook_notification(uuid()))
    end
  end

  describe "get_webhook_notification!/2" do
    test "when then webhook_notification exists, returns the webhook_notification" do
      webhook_notification_factory = insert!(:webhook_notification)

      assert %WebhookNotifications.WebhookNotification{} =
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
      webhook_notification_params = params_for(:webhook_notification, url: nil)

      assert {:error, changeset} =
               WebhookNotifications.create_webhook_notification(webhook_notification_params)

      refute changeset.valid?
    end

    test "with valid params, returns the webhook_notification" do
      webhook_notification_params = params_for(:webhook_notification)

      assert {:ok, webhook_notification} =
               WebhookNotifications.create_webhook_notification(webhook_notification_params)

      assert webhook_notification.webhook == webhook_notification_params.webhook
      assert webhook_notification.started_at == webhook_notification_params.started_at
      assert webhook_notification.url == webhook_notification_params.url
      assert webhook_notification.metadata == webhook_notification_params.metadata
      assert is_nil(webhook_notification.ended_at)

      assert [enabled_notification_type] = webhook_notification.enabled_notification_types

      assert enabled_notification_type.name ==
               Map.get(hd(webhook_notification_params.enabled_notification_types), :name)

      assert [webhook_secret] =
               WebhookNotifications.list_webhook_notification_secrets(webhook_notification)

      assert webhook_secret.is_main
    end
  end

  describe "update_webhook_notification/2" do
    test "with valid params, update the webhook_notification" do
      webhook_notification_factory = insert!(:webhook_notification)

      assert {:ok, webhook_notification} =
               WebhookNotifications.update_webhook_notification(webhook_notification_factory, %{
                 metadata: %{key: "new_value"}
               })

      assert webhook_notification.metadata == %{key: "new_value"}
      assert is_nil(webhook_notification.ended_at)
    end
  end

  describe "delete_webhook_notification/2" do
    test "with a webhook_notification that is ended, raises a FunctionClauseError" do
      webhook_notification = insert!(:webhook_notification, ended_at: @datetime_1)

      assert_raise FunctionClauseError, fn ->
        WebhookNotifications.delete_webhook_notification(webhook_notification, @datetime_1)
      end
    end

    test "with an invalid params, returns an invalid changeset" do
      webhook_notification = insert!(:webhook_notification, started_at: @datetime_2)

      assert {:error, changeset} =
               WebhookNotifications.delete_webhook_notification(webhook_notification, @datetime_1)

      refute changeset.valid?
    end

    test "with valid params, returns the ended webhook_notification" do
      webhook_notification_factory = insert!(:webhook_notification, started_at: @datetime_1)

      insert!(:webhook_notification_secret,
        webhook_notification_id: webhook_notification_factory.id,
        is_main: true,
        started_at: @datetime_1
      )

      insert!(:webhook_notification_secret,
        webhook_notification_id: webhook_notification_factory.id,
        is_main: false,
        started_at: @datetime_1
      )

      assert {:ok, webhook_notification} =
               WebhookNotifications.delete_webhook_notification(
                 webhook_notification_factory,
                 @datetime_2
               )

      assert webhook_notification.ended_at == @datetime_2

      assert [] = WebhookNotifications.list_webhook_notification_secrets(webhook_notification)
    end
  end
end
