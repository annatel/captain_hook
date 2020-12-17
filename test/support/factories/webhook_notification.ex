defmodule CaptainHook.Factory.WebhookNotification do
  alias CaptainHook.WebhookNotifications.WebhookNotification

  defmacro __using__(_opts) do
    quote do
      def build(:webhook_notification) do
        %WebhookNotification{
          webhook: "webhook_#{System.unique_integer()}",
          created_at: utc_now(),
          data: %{},
          livemode: true,
          resource_id: uuid(),
          resource_type: "resource_type_#{System.unique_integer()}",
          sequence: System.unique_integer([:positive]),
          type: "type_#{System.unique_integer()}"
        }
      end
    end
  end
end
