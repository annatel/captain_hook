defmodule CaptainHook.Factory.WebhookEndpoint do
  alias CaptainHook.WebhookEndpoints.{WebhookEndpoint, EnabledNotificationType}

  defmacro __using__(_opts) do
    quote do
      def build(:webhook_endpoint, attrs) do
        %WebhookEndpoint{
          created_at: utc_now(),
          enabled_notification_types: [build(:enabled_notification_type) |> catch_all_events()],
          headers: %{},
          livemode: true,
          url: "url_#{System.unique_integer()}"
        }
        |> put_owner_id()
        |> struct!(attrs)
      end

      defp put_owner_id(%WebhookEndpoint{} = event) do
        owner_id_value =
          if elem(CaptainHook.owner_id_field(:schema), 1) == :binary_id,
            do: uuid(),
            else: id()

        event |> Map.put(elem(CaptainHook.owner_id_field(:schema), 0), owner_id_value)
      end

      def make_enable(%WebhookEndpoint{} = webhook_endpoint),
        do: %{webhook_endpoint | is_enabled: true}

      def make_disable(%WebhookEndpoint{} = webhook_endpoint),
        do: %{webhook_endpoint | is_enabled: false}

      def make_deleted(%WebhookEndpoint{} = webhook_endpoint),
        do: %{webhook_endpoint | deleted_at: utc_now()}

      def build(:enabled_notification_type, attrs) do
        %EnabledNotificationType{
          name: "name_#{System.unique_integer()}"
        }
        |> struct!(attrs)
      end

      def catch_all_events(%EnabledNotificationType{} = enabled_notification_type) do
        %{enabled_notification_type | name: "*"}
      end
    end
  end
end
