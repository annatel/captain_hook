defmodule CaptainHook.Factory.WebhookEndpoint do
  alias CaptainHook.WebhookEndpoints.{WebhookEndpoint, EnabledNotificationType}

  defmacro __using__(_opts) do
    quote do
      def build(:webhook_endpoint) do
        %WebhookEndpoint{
          webhook: "webhook_#{System.unique_integer()}",
          started_at: utc_now(),
          livemode: true,
          is_insecure_allowed: false,
          enabled_notification_types: [build(:enabled_notification_type) |> catch_all_events()],
          headers: %{},
          url: "url_#{System.unique_integer()}"
        }
      end

      def make_ended(%WebhookEndpoint{} = webhook_endpoint) do
        %{webhook_endpoint | ended_at: utc_now()}
      end

      def build(:enabled_notification_type) do
        %EnabledNotificationType{
          name: "name_#{System.unique_integer()}"
        }
      end

      def catch_all_events(%EnabledNotificationType{} = enabled_notification_type) do
        %{enabled_notification_type | name: "*"}
      end
    end
  end
end
