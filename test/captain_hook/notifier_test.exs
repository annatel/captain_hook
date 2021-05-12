defmodule CaptainHook.NotifierTest do
  use ExUnit.Case, async: false
  use CaptainHook.DataCase

  alias CaptainHook.WebhookNotifications.WebhookNotification
  alias CaptainHook.WebhookConversations.WebhookConversation
  alias CaptainHook.Notifier

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  describe "async_notify/5" do
    test "when no webhook_endpoints exists for the webhook, creates a webhook_notification without enqueuing it" do
      assert {:ok, %WebhookNotification{}} =
               Notifier.async_notify("webhook", true, "notification_type", %{})

      Queuetopia.Test.Assertions.refute_job_created(CaptainHook.Queuetopia)
    end

    test "when no ongoing webhook_endpoints exists for the webhook, creates a webhook_notification without enqueuing it" do
      webhook_endpoint = insert!(:webhook_endpoint, started_at: utc_now(), ended_at: utc_now())

      assert {:ok, %WebhookNotification{}} =
               Notifier.async_notify(webhook_endpoint.webhook, true, "notification_type", %{})

      Queuetopia.Test.Assertions.refute_job_created(CaptainHook.Queuetopia)
    end

    test "support notifying multiple webhooks the same notification, creates a webhook_notification for each webhook" do
      assert {:ok, webhook_notifications} =
               Notifier.async_notify(["webhook1", "webhook2"], true, "notification_type", %{})

      assert webhook_notifications |> Enum.map(& &1.webhook) |> Enum.member?("webhook1")
      assert webhook_notifications |> Enum.map(& &1.webhook) |> Enum.member?("webhook2")

      Queuetopia.Test.Assertions.refute_job_created(CaptainHook.Queuetopia)
    end

    test "when the webhhok has one webhook_endpoint, creates a webhook_notification and enqueue it" do
      webhook_endpoint = insert!(:webhook_endpoint)

      assert {:ok, %WebhookNotification{} = webhook_notification} =
               Notifier.async_notify(webhook_endpoint.webhook, true, "notification_type", %{})

      Queuetopia.Test.Assertions.assert_job_created(
        CaptainHook.Queuetopia,
        "#{webhook_endpoint.webhook}_#{webhook_endpoint.id}",
        %{
          params: %{
            "webhook_endpoint_id" => webhook_endpoint.id,
            "webhook_notification_id" => webhook_notification.id,
            "webhook_result_handler" => nil
          }
        }
      )
    end

    test "when the webhook has multiple webhook_endpoints, creates a webhook_notification and enqueue them" do
      webhook = "webhook"
      webhook_endpoint_1 = insert!(:webhook_endpoint, webhook: webhook)
      webhook_endpoint_2 = insert!(:webhook_endpoint, webhook: webhook)

      assert {:ok, %WebhookNotification{} = webhook_notification} =
               Notifier.async_notify(webhook, true, "notification_type", %{})

      Queuetopia.Test.Assertions.assert_job_created(
        CaptainHook.Queuetopia,
        "#{webhook_endpoint_1.webhook}_#{webhook_endpoint_1.id}",
        %{
          params: %{
            "webhook_endpoint_id" => webhook_endpoint_1.id,
            "webhook_notification_id" => webhook_notification.id,
            "webhook_result_handler" => nil
          }
        }
      )

      Queuetopia.Test.Assertions.assert_job_created(
        CaptainHook.Queuetopia,
        "#{webhook_endpoint_2.webhook}_#{webhook_endpoint_2.id}",
        %{
          params: %{
            "webhook_endpoint_id" => webhook_endpoint_2.id,
            "webhook_notification_id" => webhook_notification.id,
            "webhook_result_handler" => nil
          }
        }
      )
    end

    test "notify multiple webhooks, when each webhook has one webhook_endpoint, creates a webhook_notification for each webhook and enqueue it for its endpoint" do
      webhook_endpoint_1 = insert!(:webhook_endpoint)
      webhook_endpoint_2 = insert!(:webhook_endpoint)

      assert {:ok, webhook_notifications} =
               Notifier.async_notify(
                 [webhook_endpoint_1.webhook, webhook_endpoint_2.webhook],
                 true,
                 "notification_type",
                 %{}
               )

      [webhook_notification_1] =
        webhook_notifications |> Enum.filter(&(&1.webhook == webhook_endpoint_1.webhook))

      [webhook_notification_2] =
        webhook_notifications |> Enum.filter(&(&1.webhook == webhook_endpoint_2.webhook))

      Queuetopia.Test.Assertions.assert_job_created(
        CaptainHook.Queuetopia,
        "#{webhook_endpoint_1.webhook}_#{webhook_endpoint_1.id}",
        %{
          params: %{
            "webhook_endpoint_id" => webhook_endpoint_1.id,
            "webhook_notification_id" => webhook_notification_1.id,
            "webhook_result_handler" => nil
          }
        }
      )

      Queuetopia.Test.Assertions.assert_job_created(
        CaptainHook.Queuetopia,
        "#{webhook_endpoint_2.webhook}_#{webhook_endpoint_2.id}",
        %{
          params: %{
            "webhook_endpoint_id" => webhook_endpoint_2.id,
            "webhook_notification_id" => webhook_notification_2.id,
            "webhook_result_handler" => nil
          }
        }
      )
    end

    test "when the webhook has webhook_endpoints and the webhook_result_handler is specified, creates a webhook_notification and enqueue it with the webhook_result_handler" do
      webhook_endpoint = insert!(:webhook_endpoint)

      assert {:ok, %WebhookNotification{} = webhook_notification} =
               Notifier.async_notify(webhook_endpoint.webhook, true, "notification_type", %{},
                 webhook_result_handler: CaptainHook.WebhookResultHandlerMock
               )

      Queuetopia.Test.Assertions.assert_job_created(
        CaptainHook.Queuetopia,
        "#{webhook_endpoint.webhook}_#{webhook_endpoint.id}",
        %{
          params: %{
            "webhook_endpoint_id" => webhook_endpoint.id,
            "webhook_notification_id" => webhook_notification.id,
            "webhook_result_handler" => to_string(CaptainHook.WebhookResultHandlerMock)
          }
        }
      )
    end
  end

  describe "send_webhook_notification/2" do
    test "when the webhook_endpoint does not have the notification_type enabled, returns an ok noop tuple" do
      webhook_endpoint = insert!(:webhook_endpoint, enabled_notification_types: [])
      webhook_notification = insert!(:webhook_notification)

      assert {:ok, :noop} =
               Notifier.send_webhook_notification(
                 %{
                   "webhook_endpoint_id" => webhook_endpoint.id,
                   "webhook_notification_id" => webhook_notification.id,
                   "webhook_result_handler" => nil
                 },
                 0
               )
    end

    test "when the conversation success, returns a ok names tuple with the webhook_conversation",
         %{bypass: bypass} do
      start_supervised(CaptainHook.Supervisor)

      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      webhook = "webhook"
      webhook_notification = insert!(:webhook_notification, webhook: webhook)

      webhook_endpoint =
        insert!(:webhook_endpoint,
          webhook: webhook,
          url: endpoint_url(bypass.port),
          headers: %{key: "value"},
          enabled_notification_types: [
            build(:enabled_notification_type, name: webhook_notification.type)
          ]
        )

      insert!(:webhook_endpoint_secret, webhook_endpoint_id: webhook_endpoint.id)

      assert {:ok, %WebhookConversation{} = webhook_conversation} =
               Notifier.send_webhook_notification(
                 %{
                   "webhook_endpoint_id" => webhook_endpoint.id,
                   "webhook_notification_id" => webhook_notification.id,
                   "webhook_result_handler" => nil
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
                 endpoint_id: webhook_endpoint.id,
                 data: webhook_notification.data
               })

      assert webhook_conversation.status == WebhookConversation.status().success
      assert Map.has_key?(webhook_conversation.request_headers, "signature")
      assert Map.get(webhook_conversation.request_headers, "key") == "value"
    end

    test "when the webhook does not have a webhook_endpoint_secret, http_client is called with secrets: nil",
         %{bypass: bypass} do
      start_supervised(CaptainHook.Supervisor)

      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      webhook = "webhook"

      webhook_endpoint =
        insert!(:webhook_endpoint,
          webhook: webhook,
          url: endpoint_url(bypass.port),
          enabled_notification_types: [
            build(:enabled_notification_type, name: "*")
          ]
        )

      webhook_notification = insert!(:webhook_notification, webhook: webhook)

      assert {:ok, %WebhookConversation{} = webhook_conversation} =
               Notifier.send_webhook_notification(
                 %{
                   "webhook_endpoint_id" => webhook_endpoint.id,
                   "webhook_notification_id" => webhook_notification.id,
                   "webhook_result_handler" => nil
                 },
                 0
               )

      refute Map.has_key?(webhook_conversation.request_headers, "Signature")
    end

    test "when is_insecure_allowed is set for the webhook_endpoint, the http_client is called with is_insecure_allowed: true" do
      start_supervised(CaptainHook.Supervisor)

      webhook = "webhook"

      webhook_endpoint =
        insert!(:webhook_endpoint,
          webhook: webhook,
          url: "https://expired.badssl.com/",
          is_insecure_allowed: true
        )

      webhook_notification = insert!(:webhook_notification, webhook: webhook)

      # Get an error since badssl does not support POST request.
      # The test is that we success to talk with the endpoint and didn't get a client error message.
      assert {:error, _webhook_conversation_as_string} =
               Notifier.send_webhook_notification(
                 %{
                   "webhook_endpoint_id" => webhook_endpoint.id,
                   "webhook_notification_id" => webhook_notification.id,
                   "webhook_result_handler" => nil
                 },
                 0
               )

      assert %{data: [webhook_conversation]} =
               CaptainHook.WebhookConversations.list_webhook_conversations()

      assert is_nil(webhook_conversation.client_error_message)
    end

    test "when the webhook endpoint does not exists, raises a Ecto.NoResultsError" do
      webhook_notification = insert!(:webhook_notification)

      assert_raise Ecto.NoResultsError, fn ->
        Notifier.send_webhook_notification(
          %{
            "webhook_endpoint_id" => "webhook_endpoint_id",
            "webhook_notification_id" => webhook_notification.id,
            "webhook_result_handler" => nil
          },
          0
        )
      end
    end

    test "when the webhook notification does not exists, raises a Ecto.NoResultsError" do
      webhook_endpoint = insert!(:webhook_endpoint)

      assert_raise Ecto.NoResultsError, fn ->
        Notifier.send_webhook_notification(
          %{
            "webhook_endpoint_id" => webhook_endpoint.id,
            "webhook_notification_id" => "webhook_notification_id",
            "webhook_result_handler" => nil
          },
          0
        )
      end
    end

    test "when the webhook_endpoint and the webhook_notification do not have the same webhook, raises a FunctionClauseError" do
      webhook_endpoint = insert!(:webhook_endpoint)
      webhook_notification = insert!(:webhook_notification)

      assert_raise FunctionClauseError, fn ->
        Notifier.send_webhook_notification(webhook_endpoint, webhook_notification)
      end
    end

    test "when the conversation failed and a webhook_result_handler is not set, returns an error named tuple with the conversation and do not call the webhook_result_handler",
         %{bypass: bypass} do
      start_supervised(CaptainHook.Supervisor)

      webhook = "webhook"

      webhook_endpoint =
        insert!(:webhook_endpoint, webhook: webhook, url: endpoint_url(bypass.port))

      webhook_notification = insert!(:webhook_notification, webhook: webhook)

      CaptainHook.WebhookResultHandlerMock
      |> expect(:handle_failure, 0, fn %WebhookConversation{}, 0 -> :ok end)

      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        Plug.Conn.resp(conn, 401, "Unauthorized")
      end)

      assert {:error, _webhook_conversation_as_string} =
               Notifier.send_webhook_notification(
                 %{
                   "webhook_endpoint_id" => webhook_endpoint.id,
                   "webhook_notification_id" => webhook_notification.id,
                   "webhook_result_handler" => nil
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

      webhook = "webhook"

      webhook_endpoint =
        insert!(:webhook_endpoint, webhook: webhook, url: endpoint_url(bypass.port))

      webhook_notification = insert!(:webhook_notification, webhook: webhook)

      CaptainHook.WebhookResultHandlerMock
      |> expect(:handle_failure, 1, fn %WebhookConversation{}, 0 -> :ok end)

      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        Plug.Conn.resp(conn, 401, "Unauthorized")
      end)

      assert {:error, _webhook_conversation_as_string} =
               Notifier.send_webhook_notification(
                 %{
                   "webhook_endpoint_id" => webhook_endpoint.id,
                   "webhook_notification_id" => webhook_notification.id,
                   "webhook_result_handler" => CaptainHook.WebhookResultHandlerMock |> to_string()
                 },
                 0
               )
    end
  end

  defp endpoint_url(port), do: "http://localhost:#{port}/"
end
