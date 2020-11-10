defmodule CaptainHook.Factory.WebhookEndpoint do
  alias CaptainHook.WebhookEndpoints.WebhookEndpoint

  defmacro __using__(_opts) do
    quote do
      def build(:webhook_endpoint) do
        %WebhookEndpoint{
          webhook: "webhook_#{System.unique_integer()}",
          started_at: utc_now(),
          livemode: true,
          url: "url_#{System.unique_integer()}",
          metadata: %{},
          headers: %{},
          allow_insecure: false
        }
      end

      def make_ended(%WebhookEndpoint{} = webhook_endpoint) do
        %{webhook_endpoint | ended_at: utc_now()}
      end
    end
  end
end
