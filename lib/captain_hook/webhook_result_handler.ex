defmodule CaptainHook.WebhookResultHandler do
  @callback handle_failure(CaptainHook.WebhookConversations.WebhookConversation.t(), integer()) ::
              any

  defmacro __using__(_opts) do
    quote do
      @behaviour unquote(__MODULE__)

      defoverridable unquote(__MODULE__)

      @impl unquote(__MODULE__)
      def handle_failure(
            %CaptainHook.WebhookConversations.WebhookConversation{} = _webhook_conversation,
            _attempt_number
          ) do
        :ok
      end
    end
  end
end
