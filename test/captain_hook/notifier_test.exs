defmodule CaptainHook.NotifierTest do
  use ExUnit.Case, async: false
  use CaptainHook.DataCase

  alias CaptainHook.WebhookConversations.WebhookConversation
  alias CaptainHook.Notifier

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  describe "send_notification/2" do
    test "when the conversation success, returns a ok names tuple with the webhook_conversation",
         %{bypass: bypass} do
      start_supervised(CaptainHook.Supervisor)

      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      webhook_endpoint =
        insert!(:webhook_endpoint,
          url: endpoint_url(bypass.port),
          metadata: %{key: "value"},
          headers: %{key: "value"}
        )

      insert!(:webhook_endpoint_secret, webhook_endpoint_id: webhook_endpoint.id)
      webhook_notification = insert!(:webhook_notification)

      assert {:ok, %WebhookConversation{} = webhook_conversation} =
               Notifier.send_notification(
                 %{
                   webhook_endpoint_id: webhook_endpoint.id,
                   webhook_notification_id: webhook_notification.id,
                   webhook_result_handler: nil
                 },
                 0
               )

      assert webhook_conversation.webhook_endpoint_id == webhook_endpoint.id
      assert webhook_conversation.webhook_notification_id == webhook_notification.id

      assert webhook_conversation.request_body ==
               Jason.encode!(%{
                 id: webhook_notification.id,
                 type: webhook_notification.type,
                 livemode: webhook_endpoint.livemode,
                 data: webhook_notification.data,
                 metadata: webhook_endpoint.metadata
               })

      assert webhook_conversation.status == WebhookConversation.status().success
      assert Map.has_key?(webhook_conversation.request_headers, "Signature")
      assert Map.get(webhook_conversation.request_headers, "Key") == "value"
    end

    test "when the webhook does not have a webhook_endpoint_secret, the http_client is called with secrets: nil",
         %{bypass: bypass} do
      start_supervised(CaptainHook.Supervisor)

      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      webhook_endpoint =
        insert!(:webhook_endpoint, url: endpoint_url(bypass.port), metadata: %{"key" => "value"})

      webhook_notification = insert!(:webhook_notification)

      assert {:ok, %WebhookConversation{} = webhook_conversation} =
               Notifier.send_notification(
                 %{
                   webhook_endpoint_id: webhook_endpoint.id,
                   webhook_notification_id: webhook_notification.id,
                   webhook_result_handler: nil
                 },
                 0
               )

      refute Map.has_key?(webhook_conversation.request_headers, "Signature")
    end

    test "when allow_insecure is set for the webhook_endpoint, the http_client is called with allow_insecure: true" do
      start_supervised(CaptainHook.Supervisor)

      webhook_endpoint =
        insert!(:webhook_endpoint,
          url: "https://expired.badssl.com/",
          allow_insecure: true
        )

      webhook_notification = insert!(:webhook_notification)

      # Get an error since badssl does not support POST request.
      # The test is that we success to talk with the endpoint and didn't get a client error message.
      assert {:error, _webhook_conversation_as_string} =
               Notifier.send_notification(
                 %{
                   webhook_endpoint_id: webhook_endpoint.id,
                   webhook_notification_id: webhook_notification.id,
                   webhook_result_handler: nil
                 },
                 0
               )

      assert %{data: [webhook_conversation]} =
               CaptainHook.WebhookConversations.list_webhook_conversations()

      assert is_nil(webhook_conversation.client_error_message)
    end

    test "when the webhook endpoint does not exists, raise a Ecto.NoResultsError" do
      webhook_notification = insert!(:webhook_notification)

      assert_raise Ecto.NoResultsError, fn ->
        Notifier.send_notification(
          %{
            webhook_endpoint_id: "webhook_endpoint_id",
            webhook_notification_id: webhook_notification.id,
            webhook_result_handler: nil
          },
          0
        )
      end
    end

    test "when the webhook notification does not exists, raise a Ecto.NoResultsError" do
      webhook_endpoint = insert!(:webhook_endpoint)

      assert_raise Ecto.NoResultsError, fn ->
        Notifier.send_notification(
          %{
            webhook_endpoint_id: webhook_endpoint.id,
            webhook_notification_id: "webhook_notification_id",
            webhook_result_handler: nil
          },
          0
        )
      end
    end

    test "when the conversation failed and a webhook_result_handler is not set, returns an error named tuple with the conversation and do not call the webhook_result_handler",
         %{bypass: bypass} do
      start_supervised(CaptainHook.Supervisor)

      webhook_endpoint = insert!(:webhook_endpoint, url: endpoint_url(bypass.port))
      webhook_notification = insert!(:webhook_notification)

      CaptainHook.WebhookResultHandlerMock
      |> expect(:handle_failure, 0, fn %WebhookConversation{}, 0 -> :ok end)

      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        Plug.Conn.resp(conn, 401, "Unauthorized")
      end)

      assert {:error, _webhook_conversation_as_string} =
               Notifier.send_notification(
                 %{
                   webhook_endpoint_id: webhook_endpoint.id,
                   webhook_notification_id: webhook_notification.id,
                   webhook_result_handler: nil
                 },
                 0
               )

      assert %{data: [webhook_conversation]} =
               CaptainHook.WebhookConversations.list_webhook_conversations()

      assert webhook_conversation.status ==
               CaptainHook.WebhookConversations.WebhookConversation.status().failed
    end

    test "when the conversation failed and a webhook_result_handler is set, call the handle_failure callback",
         %{bypass: bypass} do
      start_supervised(CaptainHook.Supervisor)

      webhook_endpoint = insert!(:webhook_endpoint, url: endpoint_url(bypass.port))
      webhook_notification = insert!(:webhook_notification)

      CaptainHook.WebhookResultHandlerMock
      |> expect(:handle_failure, 1, fn %WebhookConversation{}, 0 -> :ok end)

      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        Plug.Conn.resp(conn, 401, "Unauthorized")
      end)

      assert {:error, _webhook_conversation_as_string} =
               Notifier.send_notification(
                 %{
                   webhook_endpoint_id: webhook_endpoint.id,
                   webhook_notification_id: webhook_notification.id,
                   webhook_result_handler: CaptainHook.WebhookResultHandlerMock |> to_string()
                 },
                 0
               )
    end
  end

  defp endpoint_url(port), do: "http://localhost:#{port}/"
end
