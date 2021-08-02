defmodule CaptainHook.WebhookEndpoints.EnabledNotificationTypeTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  alias CaptainHook.WebhookEndpoints.EnabledNotificationType

  describe "changeset/2" do
    test "when the name format is invalid, returns an invalid changeset " do
      Enum.each(
        [
          params_for(:enabled_notification_type, name: "*.*"),
          params_for(:enabled_notification_type, name: ".."),
          params_for(:enabled_notification_type, name: ".a"),
          params_for(:enabled_notification_type, name: "a.")
        ],
        &assert(
          %{name: ["has invalid format"]} =
            EnabledNotificationType.changeset(%EnabledNotificationType{}, &1)
            |> errors_on()
        )
      )
    end

    test "when params are valid, return a valid changeset" do
      enabled_notification_type_params = params_for(:enabled_notification_type, name: "a.*")

      enabled_notification_type =
        EnabledNotificationType.changeset(
          %EnabledNotificationType{},
          enabled_notification_type_params
        )

      assert enabled_notification_type.valid?
    end
  end
end
