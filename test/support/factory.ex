defmodule CaptainHook.Factory do
  use ExMachina.Ecto, repo: CaptainHook.TestRepo

  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookConversations.WebhookConversation

  @spec uuid :: <<_::288>>
  def uuid() do
    Ecto.UUID.generate()
  end

  def webhook_endpoint_factory do
    %WebhookEndpoint{
      webhook: sequence("webhook_"),
      started_at: DateTime.utc_now() |> DateTime.truncate(:second),
      url: sequence("url_"),
      metadata: %{},
      headers: %{},
      allow_insecure: false
    }
  end

  def webhook_conversation_factory(attrs) do
    webhook_endpoint_id =
      Map.get(attrs, :webhook_endpoint_id) || Map.get(insert(:webhook_endpoint), :id)

    webhook_conversation = %WebhookConversation{
      webhook_endpoint_id: webhook_endpoint_id,
      resource_type: sequence("resource_type_"),
      resource_id: CaptainHook.Factory.uuid(),
      request_id: CaptainHook.Factory.uuid(),
      requested_at: DateTime.utc_now() |> DateTime.truncate(:second),
      request_url: sequence("request_url_"),
      request_headers: %{"Header-Key" => "header value"},
      request_body: sequence("request_body_"),
      http_status: 200,
      response_body: sequence("response_body_"),
      client_error_message: sequence("client_error_message_"),
      status: WebhookConversation.status().success
    }

    merge_attributes(webhook_conversation, attrs)
  end
end
