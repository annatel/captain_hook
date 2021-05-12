defmodule CaptainHook.WebhookConversations.WebhookConversationTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  alias CaptainHook.WebhookConversations.WebhookConversation

  describe "changeset/2" do
    test "only permitted_keys are casted" do
      webhook_conversation_params =
        params_for(:webhook_conversation,
          webhook_notification_id: uuid()
        )

      changeset =
        WebhookConversation.changeset(
          %WebhookConversation{},
          Map.merge(webhook_conversation_params, %{new_key: "value"})
        )

      changes_keys = changeset.changes |> Map.keys()

      assert :webhook_notification_id in changes_keys
      assert :sequence in changes_keys
      assert :requested_at in changes_keys
      assert :request_url in changes_keys
      assert :request_headers in changes_keys
      assert :request_body in changes_keys
      assert :http_status in changes_keys
      assert :response_body in changes_keys
      assert :client_error_message in changes_keys
      assert :status in changes_keys
      refute :new_key in changes_keys
    end

    test "when required params are missing, returns an invalid changeset" do
      changeset = WebhookConversation.changeset(%WebhookConversation{}, %{})

      refute changeset.valid?
      assert %{webhook_notification_id: ["can't be blank"]} = errors_on(changeset)
      assert %{requested_at: ["can't be blank"]} = errors_on(changeset)
      assert %{request_url: ["can't be blank"]} = errors_on(changeset)
      assert %{request_body: ["can't be blank"]} = errors_on(changeset)
      assert %{status: ["can't be blank"]} = errors_on(changeset)
    end

    test "when params are valid, return a valid changeset" do
      webhook_endpoint = insert!(:webhook_endpoint)
      webhook_notification = insert!(:webhook_notification)

      webhook_conversation_params =
        params_for(:webhook_conversation,
          webhook_notification_id: webhook_notification.id,
          client_error_message: "client_error_message"
        )

      changeset =
        WebhookConversation.changeset(%WebhookConversation{}, webhook_conversation_params)

      assert changeset.valid?

      assert get_field(changeset, :webhook_notification_id) ==
               webhook_conversation_params.webhook_notification_id

      assert get_field(changeset, :requested_at) == webhook_conversation_params.requested_at
      assert get_field(changeset, :request_url) == webhook_conversation_params.request_url
      assert get_field(changeset, :request_headers) == webhook_conversation_params.request_headers
      assert get_field(changeset, :request_body) == webhook_conversation_params.request_body
      assert get_field(changeset, :http_status) == webhook_conversation_params.http_status
      assert get_field(changeset, :response_body) == webhook_conversation_params.response_body

      assert get_field(changeset, :client_error_message) ==
               webhook_conversation_params.client_error_message

      assert get_field(changeset, :status) == webhook_conversation_params.status
    end
  end
end
