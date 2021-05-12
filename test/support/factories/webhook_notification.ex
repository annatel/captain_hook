defmodule CaptainHook.Factory.WebhookNotification do
  alias CaptainHook.WebhookNotifications.WebhookNotification

  defmacro __using__(_opts) do
    quote do
      def build(:webhook_notification) do
        %{id: webhook_endpoint_id} = insert!(:webhook_endpoint)

        %WebhookNotification{
          webhook_endpoint_id: webhook_endpoint_id,
          created_at: utc_now(),
          data: %{},
          resource_id: uuid(),
          resource_type: "resource_type_#{System.unique_integer()}",
          sequence: System.unique_integer([:positive]),
          type: "type_#{System.unique_integer()}"
        }
      end
    end
  end
end
