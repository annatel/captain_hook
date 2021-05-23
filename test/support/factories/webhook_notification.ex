defmodule CaptainHook.Factory.WebhookNotification do
  alias CaptainHook.WebhookNotifications.WebhookNotification

  defmacro __using__(_opts) do
    quote do
      def build(:webhook_notification, attrs) do
        %{id: webhook_endpoint_id} = insert!(:webhook_endpoint)

        %WebhookNotification{
          webhook_endpoint_id: webhook_endpoint_id,
          created_at: utc_now(),
          data: %{},
          resource_id: uuid(),
          resource_object: "resource_object_#{System.unique_integer()}",
          sequence: System.unique_integer([:positive]),
          type: "type_#{System.unique_integer()}"
        }
        |> struct!(attrs)
      end
    end
  end
end
