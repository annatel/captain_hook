defmodule CaptainHook.WebhookEndpoints.EnabledNotificationPatternTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  alias CaptainHook.WebhookEndpoints.EnabledNotificationPattern

  @notification_pattern_wildcard Application.get_env(
                                   :captain_hook,
                                   :notification_pattern_wildcard
                                 )
  describe "changeset/2" do
    test "when the name format is invalid, returns an invalid changeset " do
      Enum.each(
        [
          params_for(:enabled_notification_pattern, pattern: ".."),
          params_for(:enabled_notification_pattern, pattern: ".a"),
          params_for(:enabled_notification_pattern, pattern: "a.")
        ],
        &assert(
          %{pattern: ["has invalid format"]} =
            EnabledNotificationPattern.changeset(%EnabledNotificationPattern{}, &1)
            |> errors_on()
        )
      )
    end

    test "when params are valid, return a valid changeset" do
      enabled_notification_pattern_params =
        params_for(:enabled_notification_pattern,
          pattern: "a.#{@notification_pattern_wildcard}"
        )

      enabled_notification_pattern =
        EnabledNotificationPattern.changeset(
          %EnabledNotificationPattern{},
          enabled_notification_pattern_params
        )

      assert enabled_notification_pattern.valid?
    end
  end
end
