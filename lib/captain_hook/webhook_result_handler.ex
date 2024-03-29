defmodule CaptainHook.WebhookResultHandler do
  @callback handle_failure(
              CaptainHook.WebhookEndpoints.WebhookEndpoint.t(),
              CaptainHook.WebhookNotifications.WebhookNotification.t(),
              CaptainHook.WebhookConversations.WebhookConversation.t()
            ) ::
              any

  defmacro __using__(_opts) do
    quote do
      @behaviour CaptainHook.WebhookResultHandler

      @impl true
      def handle_failure(
            %CaptainHook.WebhookEndpoints.WebhookEndpoint{} = _webhook_endpoint,
            %CaptainHook.WebhookNotifications.WebhookNotification{} = _webhook_notification,
            %CaptainHook.WebhookConversations.WebhookConversation{} = _webhook_conversation
          ) do
        :ok
      end

      defoverridable CaptainHook.WebhookResultHandler
    end
  end
end
