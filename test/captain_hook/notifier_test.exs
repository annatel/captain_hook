defmodule CaptainHook.NotifierTest do
  use ExUnit.Case, async: false
  use CaptainHook.DataCase

  alias CaptainHook.WebhookNotifications.WebhookNotification
  alias CaptainHook.WebhookConversations
  alias CaptainHook.WebhookConversations.WebhookConversation
  alias CaptainHook.Notifier

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  describe "notify/5" do
    test "when no webhook_endpoints exists for the topic, it does not do anything" do
      assert {:ok, []} = Notifier.notify("topic", true, "notification_type", %{})
    end

    test "when no ongoing webhook_endpoints exists for the topic, it does not do anything" do
      webhook_endpoint = insert!(:webhook_endpoint, started_at: utc_now(), ended_at: utc_now())

      assert {:ok, []} = Notifier.notify(webhook_endpoint.topic, true, "notification_type", %{})
    end

    test "when the topic has one webhook_endpoint, creates a webhook_notification and send it",
         %{bypass: bypass} do
      start_supervised(CaptainHook.Supervisor)

      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      webhook_endpoint = insert!(:webhook_endpoint, url: endpoint_url(bypass.port))

      assert {:ok, [%WebhookNotification{id: webhook_notification_id} = webhook_notification]} =
               Notifier.notify(webhook_endpoint.topic, true, "notification_type", %{})

      assert [webhook_conversation] =
               WebhookConversation
               |> where(webhook_notification_id: ^webhook_notification_id)
               |> TestRepo.all()

      assert webhook_conversation.request_body ==
               Jason.encode!(
                 Map.merge(webhook_notification.data, %{
                   webhook_endpoint_id: webhook_endpoint.id
                 })
               )
    end

    test "when the notification exists with the same idempotency key, it does not create a new one",
         %{bypass: bypass} do
      start_supervised(CaptainHook.Supervisor)

      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      webhook_endpoint = insert!(:webhook_endpoint, url: endpoint_url(bypass.port))

      %{id: webhook_notification_id} =
        webhook_notification =
        insert!(:webhook_notification, webhook_endpoint_id: webhook_endpoint.id)

      assert {:ok, [%{id: ^webhook_notification_id}]} =
               Notifier.notify(webhook_endpoint.topic, true, "notification_type", %{},
                 idempotency_key: webhook_notification.idempotency_key
               )

      assert [_webhook_conversation] =
               WebhookConversation
               |> where(webhook_notification_id: ^webhook_notification_id)
               |> TestRepo.all()
    end

    test "when the webhook_notification exists and it is already succeed, do not send it",
         %{bypass: bypass} do
      start_supervised(CaptainHook.Supervisor)

      webhook_endpoint = insert!(:webhook_endpoint, url: endpoint_url(bypass.port))

      %{id: webhook_notification_id} =
        webhook_notification =
        insert!(:webhook_notification,
          webhook_endpoint_id: webhook_endpoint.id,
          succeeded_at: utc_now()
        )

      assert {:ok, [%{id: ^webhook_notification_id}]} =
               Notifier.notify(webhook_endpoint.topic, true, "notification_type", %{},
                 idempotency_key: webhook_notification.idempotency_key
               )

      assert [] =
               WebhookConversation
               |> where(webhook_notification_id: ^webhook_notification_id)
               |> TestRepo.all()
    end
  end

  describe "async_notify/5" do
    test "when no webhook_endpoints exists for the topic, it does not do anything" do
      assert {:ok, []} = Notifier.async_notify("topic", true, "notification_type", %{})
      Queuetopia.Test.Assertions.refute_job_created(CaptainHook.Queuetopia)
    end

    test "when no ongoing webhook_endpoints exists for the topic, it does not do anything" do
      webhook_endpoint = insert!(:webhook_endpoint, started_at: utc_now(), ended_at: utc_now())

      assert {:ok, []} =
               Notifier.async_notify(webhook_endpoint.topic, true, "notification_type", %{})
    end

    test "when the topic has one webhook_endpoint, creates a webhook_notification and enqueue it" do
      webhook_endpoint = insert!(:webhook_endpoint)

      assert {:ok, [%WebhookNotification{} = webhook_notification]} =
               Notifier.async_notify(webhook_endpoint.topic, true, "notification_type", %{})

      Queuetopia.Test.Assertions.assert_job_created(
        CaptainHook.Queuetopia,
        "#{webhook_endpoint.topic}_#{webhook_endpoint.id}",
        %{
          params: %{
            "webhook_notification_id" => webhook_notification.id,
            "webhook_result_handler" => nil
          }
        }
      )
    end

    test "when the topic has multiple webhook_endpoints, creates multiple webhook_notifications for each endpoint and enqueue them" do
      topic = "topic"
      webhook_endpoint_1 = insert!(:webhook_endpoint, topic: topic)
      webhook_endpoint_2 = insert!(:webhook_endpoint, topic: topic)

      assert {:ok, webhook_notifications} =
               Notifier.async_notify(topic, true, "notification_type", %{})

      assert length(webhook_notifications) == 2

      webhook_notification_1 =
        webhook_notifications |> Enum.find(&(&1.webhook_endpoint_id == webhook_endpoint_1.id))

      webhook_notification_2 =
        webhook_notifications |> Enum.find(&(&1.webhook_endpoint_id == webhook_endpoint_2.id))

      Queuetopia.Test.Assertions.assert_job_created(
        CaptainHook.Queuetopia,
        "#{webhook_endpoint_1.topic}_#{webhook_endpoint_1.id}",
        %{
          params: %{
            "webhook_notification_id" => webhook_notification_1.id,
            "webhook_result_handler" => nil
          }
        }
      )

      Queuetopia.Test.Assertions.assert_job_created(
        CaptainHook.Queuetopia,
        "#{webhook_endpoint_2.topic}_#{webhook_endpoint_2.id}",
        %{
          params: %{
            "webhook_notification_id" => webhook_notification_2.id,
            "webhook_result_handler" => nil
          }
        }
      )
    end

    test "notify multiple topics, when each topic has one webhook_endpoint, creates multiple webhook_notifications for each webhook_endpoint and enqueue them" do
      webhook_endpoint_1 = insert!(:webhook_endpoint)
      webhook_endpoint_2 = insert!(:webhook_endpoint)
      webhook_endpoint_3 = insert!(:webhook_endpoint, topic: webhook_endpoint_2.topic)

      assert {:ok, webhook_notifications} =
               Notifier.async_notify(
                 [webhook_endpoint_1.topic, webhook_endpoint_2.topic],
                 true,
                 "notification_type",
                 %{}
               )

      assert length(webhook_notifications) == 3

      [webhook_notification_1] =
        webhook_notifications |> Enum.filter(&(&1.webhook_endpoint_id == webhook_endpoint_1.id))

      [webhook_notification_2] =
        webhook_notifications |> Enum.filter(&(&1.webhook_endpoint_id == webhook_endpoint_2.id))

      [webhook_notification_3] =
        webhook_notifications |> Enum.filter(&(&1.webhook_endpoint_id == webhook_endpoint_3.id))

      Queuetopia.Test.Assertions.assert_job_created(
        CaptainHook.Queuetopia,
        "#{webhook_endpoint_1.topic}_#{webhook_endpoint_1.id}",
        %{
          params: %{
            "webhook_notification_id" => webhook_notification_1.id,
            "webhook_result_handler" => nil
          }
        }
      )

      Queuetopia.Test.Assertions.assert_job_created(
        CaptainHook.Queuetopia,
        "#{webhook_endpoint_2.topic}_#{webhook_endpoint_2.id}",
        %{
          params: %{
            "webhook_notification_id" => webhook_notification_2.id,
            "webhook_result_handler" => nil
          }
        }
      )

      Queuetopia.Test.Assertions.assert_job_created(
        CaptainHook.Queuetopia,
        "#{webhook_endpoint_3.topic}_#{webhook_endpoint_3.id}",
        %{
          params: %{
            "webhook_notification_id" => webhook_notification_3.id,
            "webhook_result_handler" => nil
          }
        }
      )
    end

    test "when webhook_result_handler is specified, enqueue the webhook_notification with the webhook_result_handler" do
      webhook_endpoint = insert!(:webhook_endpoint)

      assert {:ok, [webhook_notification]} =
               Notifier.async_notify(webhook_endpoint.topic, true, "notification_type", %{},
                 webhook_result_handler: CaptainHook.WebhookResultHandlerMock
               )

      Queuetopia.Test.Assertions.assert_job_created(
        CaptainHook.Queuetopia,
        "#{webhook_endpoint.topic}_#{webhook_endpoint.id}",
        %{
          params: %{
            "webhook_notification_id" => webhook_notification.id,
            "webhook_result_handler" => to_string(CaptainHook.WebhookResultHandlerMock)
          }
        }
      )
    end

    test "when the notification exists with the same idempotency key, it does not create a new one" do
      webhook_endpoint = insert!(:webhook_endpoint)

      %{id: webhook_notification_id} =
        webhook_notification =
        insert!(:webhook_notification, webhook_endpoint_id: webhook_endpoint.id)

      assert {:ok, [%{id: ^webhook_notification_id}]} =
               Notifier.async_notify(webhook_endpoint.topic, true, "notification_type", %{},
                 idempotency_key: webhook_notification.idempotency_key
               )

      Queuetopia.Test.Assertions.assert_job_created(
        CaptainHook.Queuetopia,
        "#{webhook_endpoint.topic}_#{webhook_endpoint.id}",
        %{
          params: %{
            "webhook_notification_id" => webhook_notification_id,
            "webhook_result_handler" => nil
          }
        }
      )
    end
  end

  describe "send_webhook_notification/2" do
    test "when the webhook_endpoint is disabled, returns an ok noop tuple",
         %{bypass: bypass} do
      start_supervised(CaptainHook.Supervisor)

      webhook_endpoint =
        build(:webhook_endpoint, url: endpoint_url(bypass.port)) |> make_disable() |> insert!()

      webhook_notification =
        insert!(:webhook_notification, webhook_endpoint_id: webhook_endpoint.id)

      assert {:ok, :noop} =
               Notifier.send_webhook_notification(%{
                 "webhook_notification_id" => webhook_notification.id,
                 "webhook_result_handler" => nil
               })
    end

    test "when the webhook_notification is already succeed, returns the notification without sending it",
         %{bypass: bypass} do
      start_supervised(CaptainHook.Supervisor)

      webhook_endpoint = insert!(:webhook_endpoint, url: endpoint_url(bypass.port))

      %{id: webhook_notification_id} =
        webhook_notification =
        insert!(:webhook_notification,
          webhook_endpoint_id: webhook_endpoint.id,
          succeeded_at: utc_now()
        )

      assert {:ok, %{id: ^webhook_notification_id}} =
               Notifier.send_webhook_notification(%{
                 "webhook_notification_id" => webhook_notification.id,
                 "webhook_result_handler" => nil
               })

      assert [] =
               WebhookConversation
               |> where(webhook_notification_id: ^webhook_notification_id)
               |> TestRepo.all()
    end

    test "when the webhook_notification is not succeed, send the webhook_notification and returns a ok names tuple with the webhook_conversation",
         %{bypass: bypass} do
      start_supervised(CaptainHook.Supervisor)

      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      webhook_endpoint =
        insert!(:webhook_endpoint, url: endpoint_url(bypass.port), headers: %{key: "value"})

      insert!(:webhook_endpoint_secret, webhook_endpoint_id: webhook_endpoint.id)

      %{id: webhook_notification_id} =
        webhook_notification =
        insert!(:webhook_notification,
          webhook_endpoint_id: webhook_endpoint.id,
          data: %{key: "value"}
        )

      assert {:ok, %WebhookNotification{id: ^webhook_notification_id} = webhook_notification} =
               Notifier.send_webhook_notification(%{
                 "webhook_notification_id" => webhook_notification.id,
                 "webhook_result_handler" => nil
               })

      assert_in_delta DateTime.to_unix(webhook_notification.succeeded_at),
                      DateTime.to_unix(utc_now()),
                      5

      assert [webhook_conversation] =
               WebhookConversation
               |> where(webhook_notification_id: ^webhook_notification_id)
               |> TestRepo.all()

      assert webhook_conversation.request_body ==
               Jason.encode!(
                 Map.merge(webhook_notification.data, %{
                   webhook_endpoint_id: webhook_endpoint.id
                 })
               )

      assert webhook_conversation.status == WebhookConversation.statuses().succeeded
      assert Map.has_key?(webhook_conversation.request_headers, "signature")
      assert Map.get(webhook_conversation.request_headers, "key") == "value"
    end

    test "when the webhook_endpoint does not have a webhook_endpoint_secret, http_client is called with secrets: nil",
         %{bypass: bypass} do
      start_supervised(CaptainHook.Supervisor)

      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      webhook_endpoint = insert!(:webhook_endpoint, url: endpoint_url(bypass.port))

      webhook_notification =
        insert!(:webhook_notification, webhook_endpoint_id: webhook_endpoint.id)

      assert {:ok, %WebhookNotification{id: webhook_notification_id}} =
               Notifier.send_webhook_notification(%{
                 "webhook_notification_id" => webhook_notification.id,
                 "webhook_result_handler" => nil
               })

      assert [webhook_conversation] =
               WebhookConversation
               |> where(webhook_notification_id: ^webhook_notification_id)
               |> TestRepo.all()

      refute Map.has_key?(webhook_conversation.request_headers, "Signature")
    end

    test "when is_insecure_allowed is set for the webhook_endpoint, the http_client is called with is_insecure_allowed: true" do
      start_supervised(CaptainHook.Supervisor)

      webhook_endpoint =
        insert!(:webhook_endpoint,
          url: "https://expired.badssl.com/",
          is_insecure_allowed: true
        )

      %{id: webhook_notification_id} =
        insert!(:webhook_notification, webhook_endpoint_id: webhook_endpoint.id)

      # Get an error since badssl does not support POST request.
      # The test is that we success to talk with the endpoint and didn't get a client error message.
      assert {:error, _webhook_conversation_as_string} =
               Notifier.send_webhook_notification(%{
                 "webhook_notification_id" => webhook_notification_id,
                 "webhook_result_handler" => nil
               })

      assert [webhook_conversation] =
               WebhookConversation
               |> where(webhook_notification_id: ^webhook_notification_id)
               |> TestRepo.all()

      assert is_nil(webhook_conversation.client_error_message)
    end

    test "when the webhook notification does not exists, raises a Ecto.NoResultsError" do
      assert_raise Ecto.NoResultsError, fn ->
        Notifier.send_webhook_notification(%{
          "webhook_notification_id" => shortcode_uuid("wn"),
          "webhook_result_handler" => nil
        })
      end
    end

    test "when the conversation failed and a webhook_result_handler is not set, returns an error named tuple with the conversation and do not call the webhook_result_handler",
         %{bypass: bypass} do
      start_supervised(CaptainHook.Supervisor)

      webhook_endpoint = insert!(:webhook_endpoint, url: endpoint_url(bypass.port))

      %{id: webhook_notification_id} =
        insert!(:webhook_notification, webhook_endpoint_id: webhook_endpoint.id)

      CaptainHook.WebhookResultHandlerMock
      |> expect(:handle_failure, 0, fn %WebhookNotification{}, %WebhookConversation{} ->
        :ok
      end)

      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        Plug.Conn.resp(conn, 401, "Unauthorized")
      end)

      assert {:error, _webhook_conversation_as_string} =
               Notifier.send_webhook_notification(%{
                 "webhook_notification_id" => webhook_notification_id,
                 "webhook_result_handler" => nil
               })

      assert [webhook_conversation] =
               WebhookConversation
               |> where(webhook_notification_id: ^webhook_notification_id)
               |> TestRepo.all()

      assert webhook_conversation.status ==
               WebhookConversations.WebhookConversation.statuses().failed
    end

    test "when the conversation failed and a webhook_result_handler is set, call the handle_failure callback",
         %{bypass: bypass} do
      start_supervised(CaptainHook.Supervisor)

      webhook_endpoint = insert!(:webhook_endpoint, url: endpoint_url(bypass.port))

      webhook_notification =
        insert!(:webhook_notification, webhook_endpoint_id: webhook_endpoint.id)

      CaptainHook.WebhookResultHandlerMock
      |> expect(:handle_failure, 1, fn %WebhookNotification{}, %WebhookConversation{} ->
        :ok
      end)

      Bypass.expect_once(bypass, "POST", "/", fn conn ->
        Plug.Conn.resp(conn, 401, "Unauthorized")
      end)

      assert {:error, _webhook_conversation_as_string} =
               Notifier.send_webhook_notification(%{
                 "webhook_notification_id" => webhook_notification.id,
                 "webhook_result_handler" => CaptainHook.WebhookResultHandlerMock |> to_string()
               })
    end
  end

  defp endpoint_url(port), do: "http://localhost:#{port}/"
end
