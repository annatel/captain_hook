defmodule CaptainHook.Factory.WebhookConversation do
  alias CaptainHook.WebhookConversations.WebhookConversation

  defmacro __using__(_opts) do
    quote do
      def build(:webhook_conversation, attrs) do
        %WebhookConversation{
          sequence: System.unique_integer([:positive]),
          requested_at: utc_now(),
          request_url: "request_url_#{System.unique_integer()}🤯",
          request_headers: %{"Header-Key" => "header value"},
          request_body: "request_body_#{System.unique_integer()}🤯",
          http_status: 200,
          response_body: "response_body_#{System.unique_integer()}🤯",
          client_error_message: "client_error_message_#{System.unique_integer()}🤯",
          status: WebhookConversation.statuses().succeeded
        }
        |> struct!(attrs)
      end
    end
  end
end
