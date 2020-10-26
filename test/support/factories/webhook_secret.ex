defmodule CaptainHook.Factory.WebhookSecret do
  alias CaptainHook.WebhookSecrets.WebhookSecret

  defmacro __using__(_opts) do
    quote do
      def build(:webhook_secret) do
        %WebhookSecret{
          started_at: utc_now()
        }
      end

      def make_ended(%WebhookSecret{} = webhook_endpoint) do
        %{webhook_endpoint | ended_at: utc_now()}
      end
    end
  end
end
