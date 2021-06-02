defmodule CaptainHook.WebhookResultHandler do
  @callback handle_failure(
              CaptainHook.WebhookNotifications.WebhookNotification.t(),
              CaptainHook.WebhookConversations.WebhookConversation.t()
            ) ::
              any

  defmacro __using__(_opts) do
    quote do
      @behaviour CaptainHook.WebhookResultHandler

      defoverridable CaptainHook.WebhookResultHandler

      @impl true
      def handle_failure(
            %CaptainHook.WebhookNotifications.WebhookNotification{} = _webhook_notification,
            %CaptainHook.WebhookConversations.WebhookConversation{} = _webhook_conversation
          ) do
        :ok
      end
    end
  end
end
