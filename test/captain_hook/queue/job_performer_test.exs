defmodule CaptainHook.Queue.JobPerformerTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  import Mox

  alias CaptainHook.Queue.JobPerformer
  alias CaptainHook.WebhookConversations.WebhookConversation

  setup :verify_on_exit!

  describe "send_notification/3" do
    test "when the webhook (name) does not exists, raise a Ecto.NoResultsError" do
      webhook_endpoint = insert(:webhook_endpoint, webhook: "webhook1")

      assert_raise Ecto.NoResultsError, fn ->
        JobPerformer.send_notification(
          "action",
          %{
            webhook: "webhook2",
            webhook_endpoint_id: webhook_endpoint.id,
            schema_type: "schema_type",
            schema_id: "schema_id",
            data: %{}
          },
          0
        )
      end
    end

    test "when the webhook_endpoint_id does not exists, raise a Ecto.NoResultsError" do
      webhook_endpoint = insert(:webhook_endpoint)

      assert_raise Ecto.NoResultsError, fn ->
        JobPerformer.send_notification(
          "action",
          %{
            webhook: webhook_endpoint.webhook,
            webhook_endpoint_id: CaptainHook.Factory.uuid(),
            schema_type: "schema_type",
            schema_id: "schema_id",
            data: %{}
          },
          0
        )
      end
    end

    test "when the conversation failed, returns an error named tuple with the conversation" do
      %{url: url} = webhook_endpoint = insert(:webhook_endpoint)

      data = %{}
      encoded_params = Jason.encode!(data)

      CaptainHook.HttpAdapterMock
      |> expect(:post, fn ^url,
                          ^encoded_params,
                          [{"Content-Type", "application/json"}],
                          _options ->
        {:error, %HTTPoison.Error{reason: :connect_timeout}}
      end)

      params = %{
        webhook: webhook_endpoint.webhook,
        webhook_endpoint_id: webhook_endpoint.id,
        schema_type: "schema_type",
        schema_id: "schema_id",
        data: data
      }

      assert {:error, _webhook_conversation_as_string} =
               JobPerformer.send_notification("action", params, 0)
    end

    test "when the conversation failed and a webhook_result_handler is not set, do not call the handle_failure callback" do
      webhook_endpoint = insert(:webhook_endpoint)

      CaptainHook.HttpAdapterMock
      |> expect(:post, fn _, _, _, _ -> {:error, %HTTPoison.Error{reason: :connect_timeout}} end)

      CaptainHook.WebhookResultHandlerMock
      |> expect(:handle_failure, 0, fn %WebhookConversation{}, 0 -> :ok end)

      params = %{
        webhook: webhook_endpoint.webhook,
        webhook_endpoint_id: webhook_endpoint.id,
        schema_type: "schema_type",
        schema_id: "schema_id",
        data: %{}
      }

      assert {:error, _webhook_conversation_as_string} =
               JobPerformer.send_notification("action", params, 0)
    end

    test "when the conversation failed and a webhook_result_handler is set, call the handle_failure callback" do
      webhook_endpoint = insert(:webhook_endpoint)

      CaptainHook.HttpAdapterMock
      |> expect(:post, fn _, _, _, _ -> {:error, %HTTPoison.Error{reason: :connect_timeout}} end)

      CaptainHook.WebhookResultHandlerMock
      |> expect(:handle_failure, 1, fn %WebhookConversation{}, 0 -> :ok end)

      params = %{
        webhook: webhook_endpoint.webhook,
        webhook_endpoint_id: webhook_endpoint.id,
        schema_type: "schema_type",
        schema_id: "schema_id",
        webhook_result_handler: CaptainHook.WebhookResultHandlerMock |> to_string(),
        data: %{}
      }

      assert {:error, _webhook_conversation_as_string} =
               JobPerformer.send_notification("action", params, 0)
    end

    test "when the conversation success, returns a ok names tuple with the webhook_conversation" do
      %{url: url} = webhook_endpoint = insert(:webhook_endpoint)

      data = %{}
      encoded_params = Jason.encode!(data)

      CaptainHook.HttpAdapterMock
      |> expect(:post, fn ^url,
                          ^encoded_params,
                          [{"Content-Type", "application/json"}],
                          _options ->
        {:ok, %HTTPoison.Response{status_code: 200, body: "OK"}}
      end)

      params = %{
        webhook: webhook_endpoint.webhook,
        webhook_endpoint_id: webhook_endpoint.id,
        schema_type: "schema_type",
        schema_id: "schema_id",
        data: data
      }

      assert {:ok, %WebhookConversation{status: status}} =
               JobPerformer.send_notification("action", params, 0)

      assert status == WebhookConversation.status().success
    end
  end
end
