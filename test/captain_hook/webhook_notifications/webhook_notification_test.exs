defmodule CaptainHook.WebhookNotifications.WebhookNotificationTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  alias CaptainHook.WebhookNotifications.WebhookNotification

  describe "create_changeset/2" do
    test "only permitted_keys are casted" do
      webhook_notification_params = params_for(:webhook_notification)

      changeset =
        WebhookNotification.create_changeset(
          %WebhookNotification{},
          Map.merge(webhook_notification_params, %{new_key: "value"})
        )

      changes_keys = changeset.changes |> Map.keys()

      assert :webhook_endpoint_id in changes_keys
      assert :created_at in changes_keys
      assert :data in changes_keys
      assert :resource_id in changes_keys
      assert :resource_object in changes_keys
      assert :sequence in changes_keys
      assert :type in changes_keys
      refute :ended_at in changes_keys
      refute :new_key in changes_keys
    end

    test "when required params are missing, returns an invalid changeset" do
      changeset = WebhookNotification.create_changeset(%WebhookNotification{}, %{})

      refute changeset.valid?
      assert %{webhook_endpoint_id: ["can't be blank"]} = errors_on(changeset)
      assert %{created_at: ["can't be blank"]} = errors_on(changeset)
      assert %{data: ["can't be blank"]} = errors_on(changeset)
      assert %{sequence: ["can't be blank"]} = errors_on(changeset)
      assert %{type: ["can't be blank"]} = errors_on(changeset)
    end

    test "when the type format is invalid, returns an invalid changeset" do
      Enum.each(
        [
          params_for(:webhook_notification, type: "*"),
          params_for(:webhook_notification, type: ".."),
          params_for(:webhook_notification, type: ".a"),
          params_for(:webhook_notification, type: "a.")
        ],
        &assert(
          %{type: ["has invalid format"]} =
            WebhookNotification.create_changeset(%WebhookNotification{}, &1)
            |> errors_on()
        )
      )
    end

    test "when params are valid, return a valid changeset" do
      webhook_notification_params = params_for(:webhook_notification)

      changeset =
        WebhookNotification.create_changeset(%WebhookNotification{}, webhook_notification_params)

      assert changeset.valid?

      assert get_field(changeset, :webhook_endpoint_id) ==
               webhook_notification_params.webhook_endpoint_id

      assert get_field(changeset, :created_at) == webhook_notification_params.created_at
      assert get_field(changeset, :data) == webhook_notification_params.data
      assert get_field(changeset, :resource_id) == webhook_notification_params.resource_id
      assert get_field(changeset, :resource_object) == webhook_notification_params.resource_object
      assert get_field(changeset, :sequence) == webhook_notification_params.sequence
      assert get_field(changeset, :type) == webhook_notification_params.type
    end
  end
end
