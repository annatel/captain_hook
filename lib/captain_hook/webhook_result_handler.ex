defmodule CaptainHook.WebhookResultHandler do
  @callback handle_failure(
              CaptainHook.WebhookNotifications.WebhookNotification.t(),
              CaptainHook.WebhookConversations.WebhookConversation.t()
            ) ::
              any

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)

      defoverridable unquote(__MODULE__)

      @impl unquote(__MODULE__)
      def handle_failure(
            %CaptainHook.WebhookNotifications.WebhookNotification{} = _webhook_notification,
            %CaptainHook.WebhookConversations.WebhookConversation{} = _webhook_conversation
          ) do
        :ok
      end
    end
  end
end
