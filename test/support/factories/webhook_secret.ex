defmodule CaptainHook.Factory.WebhookSecret do
  alias CaptainHook.WebhookSecrets
  alias CaptainHook.WebhookSecrets.WebhookSecret

  defmacro __using__(_opts) do
    quote do
      def build(:webhook_secret) do
        %{id: webhook_endpoint_id} = insert!(:webhook_endpoint)

        %WebhookSecret{
          webhook_endpoint_id: webhook_endpoint_id,
          started_at: utc_now(),
          secret: WebhookSecrets.generate_secret(),
          main?: true
        }
      end

      def make_ended(%WebhookSecret{} = webhook_endpoint) do
        %{webhook_endpoint | ended_at: utc_now()}
      end
    end
  end
end
