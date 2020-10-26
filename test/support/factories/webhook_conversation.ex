defmodule CaptainHook.Factory.WebhookConversation do
  alias CaptainHook.WebhookConversations.WebhookConversation

  defmacro __using__(_opts) do
    quote do
      def build(:webhook_conversation) do
        %{id: webhook_endpoint_id} = insert!(:webhook_endpoint)

        %WebhookConversation{
          webhook_endpoint_id: webhook_endpoint_id,
          resource_type: "resource_type_#{System.unique_integer()}",
          resource_id: uuid(),
          request_id: uuid(),
          requested_at: utc_now(),
          request_url: "request_url_#{System.unique_integer()}",
          request_headers: %{"Header-Key" => "header value"},
          request_body: "request_body_#{System.unique_integer()}",
          http_status: 200,
          response_body: "response_body_#{System.unique_integer()}",
          client_error_message: "response_body_#{System.unique_integer()}",
          status: WebhookConversation.status().success
        }
      end
    end
  end
end
