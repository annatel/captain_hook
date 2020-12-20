defmodule CaptainHook.Factory.WebhookEndpointSecret do
  alias CaptainHook.WebhookEndpoints.Secrets
  alias CaptainHook.WebhookEndpoints.Secrets.WebhookEndpointSecret

  defmacro __using__(_opts) do
    quote do
      def build(:webhook_endpoint_secret) do
        %WebhookEndpointSecret{
          started_at: utc_now(),
          secret: Secrets.generate_secret(),
          is_main: true
        }
      end

      def make_ended(%WebhookEndpointSecret{} = webhook_endpoint_endpoint) do
        %{webhook_endpoint_endpoint | ended_at: utc_now()}
      end
    end
  end
end
