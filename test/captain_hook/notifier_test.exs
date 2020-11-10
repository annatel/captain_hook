defmodule CaptainHook.NotifierTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  # alias CaptainHook.WebhookConversations.WebhookConversation

  # describe "send_notification/3" do
  #   test "params from captain_hook_queue can be either a Map with atom keys or string keys" do
  #     webhook_endpoint = insert!(:webhook_endpoint)

  #     CaptainHook.HttpAdapterMock
  #     |> stub(:post, fn _, _, _, _ ->
  #       {:ok, %HTTPoison.Response{status_code: 200, body: "OK"}}
  #     end)

  #     map_with_string_keys = %{
  #       "webhook" => webhook_endpoint.webhook,
  #       "webhook_endpoint_id" => webhook_endpoint.id,
  #       "resource_type" => "resource_type",
  #       "resource_id" => "resource_id",
  #       "request_id" => Ecto.UUID.generate(),
  #       "data" => %{}
  #     }

  #     map_with_atom_keys = %{
  #       webhook: webhook_endpoint.webhook,
  #       webhook_endpoint_id: webhook_endpoint.id,
  #       resource_type: "resource_type",
  #       resource_id: "resource_id",
  #       request_id: Ecto.UUID.generate(),
  #       data: %{}
  #     }

  #     assert {:ok, %WebhookConversation{}} =
  #              JobPerformer.send_notification("action", map_with_string_keys, 0)

  #     assert {:ok, %WebhookConversation{}} =
  #              JobPerformer.send_notification("action", map_with_atom_keys, 0)
  #   end

  #   test "when the webhook (name) does not exists, raise a Ecto.NoResultsError" do
  #     webhook_endpoint = insert!(:webhook_endpoint, webhook: "webhook1")

  #     params =
  #       CaptainHook.DataWrapper.new(
  #         "webhook2",
  #         webhook_endpoint.id,
  #         "resource_type",
  #         "resource_id",
  #         %{},
  #         []
  #       )
  #       |> Map.from_struct()

  #     assert_raise Ecto.NoResultsError, fn ->
  #       JobPerformer.send_notification("action", params, 0)
  #     end
  #   end

  #   test "when the webhook_endpoint_id does not exists, raise a Ecto.NoResultsError" do
  #     webhook_endpoint = insert!(:webhook_endpoint)

  #     params =
  #       CaptainHook.DataWrapper.new(
  #         webhook_endpoint.webhook,
  #         CaptainHook.Factory.uuid(),
  #         "resource_type",
  #         "resource_id",
  #         %{},
  #         []
  #       )
  #       |> Map.from_struct()

  #     assert_raise Ecto.NoResultsError, fn ->
  #       JobPerformer.send_notification("action", params, 0)
  #     end
  #   end

  #   test "when the conversation failed, returns an error named tuple with the conversation" do
  #     webhook_endpoint = insert!(:webhook_endpoint)

  #     CaptainHook.HttpAdapterMock
  #     |> expect(:post, fn _, _, _, _options ->
  #       {:error, %HTTPoison.Error{reason: :connect_timeout}}
  #     end)

  #     params =
  #       CaptainHook.DataWrapper.new(
  #         webhook_endpoint.webhook,
  #         webhook_endpoint.id,
  #         "resource_type",
  #         "resource_id",
  #         %{},
  #         []
  #       )
  #       |> Map.from_struct()

  #     assert {:error, _webhook_conversation_as_string} =
  #              JobPerformer.send_notification("action", params, 0)

  #     assert %{data: [webhook_conversation]} =
  #              CaptainHook.WebhookConversations.list_webhook_conversations(
  #                webhook_endpoint.webhook,
  #                webhook_endpoint
  #              )

  #     assert webhook_conversation.status ==
  #              CaptainHook.WebhookConversations.WebhookConversation.status().failed
  #   end

  #   test "when the conversation failed and a webhook_result_handler is not set, do not call the handle_failure callback" do
  #     webhook_endpoint = insert!(:webhook_endpoint)

  #     CaptainHook.HttpAdapterMock
  #     |> expect(:post, fn _, _, _, _ -> {:error, %HTTPoison.Error{reason: :connect_timeout}} end)

  #     CaptainHook.WebhookResultHandlerMock
  #     |> expect(:handle_failure, 0, fn %WebhookConversation{}, 0 -> :ok end)

  #     params =
  #       CaptainHook.DataWrapper.new(
  #         webhook_endpoint.webhook,
  #         webhook_endpoint.id,
  #         "resource_type",
  #         "resource_id",
  #         %{},
  #         []
  #       )
  #       |> Map.from_struct()

  #     assert {:error, _webhook_conversation_as_string} =
  #              JobPerformer.send_notification("action", params, 0)
  #   end

  #   test "when the conversation failed and a webhook_result_handler is set, call the handle_failure callback" do
  #     webhook_endpoint = insert!(:webhook_endpoint)

  #     CaptainHook.HttpAdapterMock
  #     |> expect(:post, fn _, _, _, _ -> {:error, %HTTPoison.Error{reason: :connect_timeout}} end)

  #     status = WebhookConversation.status().failed

  #     CaptainHook.WebhookResultHandlerMock
  #     |> expect(:handle_failure, 1, fn %WebhookConversation{status: ^status}, 0 -> :ok end)

  #     params =
  #       CaptainHook.DataWrapper.new(
  #         webhook_endpoint.webhook,
  #         webhook_endpoint.id,
  #         "resource_type",
  #         "resource_id",
  #         %{},
  #         webhook_result_handler: CaptainHook.WebhookResultHandlerMock |> to_string()
  #       )
  #       |> Map.from_struct()

  #     assert {:error, _webhook_conversation_as_string} =
  #              JobPerformer.send_notification("action", params, 0)
  #   end

  #   test "when the conversation success, returns a ok names tuple with the webhook_conversation" do
  #     webhook_endpoint = insert!(:webhook_endpoint)
  #     _webhook_secret = insert!(:webhook_secret, webhook_endpoint_id: webhook_endpoint.id)

  #     CaptainHook.HttpAdapterMock
  #     |> expect(:post, fn _, _, _, _options ->
  #       {:ok, %HTTPoison.Response{status_code: 200, body: "OK"}}
  #     end)

  #     params =
  #       CaptainHook.DataWrapper.new(
  #         webhook_endpoint.webhook,
  #         webhook_endpoint.id,
  #         "resource_type",
  #         "resource_id",
  #         %{},
  #         []
  #       )
  #       |> Map.from_struct()

  #     assert {:ok, %WebhookConversation{status: status}} =
  #              JobPerformer.send_notification("action", params, 0)

  #     assert status == WebhookConversation.status().success
  #   end

  #   test "add the request_id to the body request when notifying the endpoint" do
  #     %{url: url} = webhook_endpoint = insert!(:webhook_endpoint)

  #     data = %{id: "1"}

  #     params =
  #       CaptainHook.DataWrapper.new(
  #         webhook_endpoint.webhook,
  #         webhook_endpoint.id,
  #         "resource_type",
  #         "resource_id",
  #         data,
  #         []
  #       )
  #       |> Map.from_struct()

  #     encoded_params = data |> Map.put(:request_id, params.request_id) |> Jason.encode!()

  #     CaptainHook.HttpAdapterMock
  #     |> expect(:post, fn ^url, ^encoded_params, _, _options ->
  #       {:ok, %HTTPoison.Response{status_code: 200, body: "OK"}}
  #     end)

  #     assert {:ok, %WebhookConversation{}} = JobPerformer.send_notification("action", params, 0)
  #   end

  #   test "add the webhook_endpoint headers to the request when notifying the endpoint" do
  #     %{url: url} =
  #       webhook_endpoint =
  #       insert!(:webhook_endpoint,
  #         headers: %{
  #           "authorization" => "Basic bG9naW46cGFzc3dvcmQ=",
  #           "some header" => "some value"
  #         }
  #       )

  #     headers = [
  #       {"Authorization", "Basic bG9naW46cGFzc3dvcmQ="},
  #       {"Content-Type", "application/json"},
  #       {"Some-Header", "some value"},
  #       {"User-Agent", "CaptainHook/1.0; +(https://github.com/annatel/captain_hook)"}
  #     ]

  #     CaptainHook.HttpAdapterMock
  #     |> expect(:post, fn ^url, _, ^headers, _options ->
  #       {:ok, %HTTPoison.Response{status_code: 200, body: "OK"}}
  #     end)

  #     params =
  #       CaptainHook.DataWrapper.new(
  #         webhook_endpoint.webhook,
  #         webhook_endpoint.id,
  #         "resource_type",
  #         "resource_id",
  #         %{},
  #         []
  #       )
  #       |> Map.from_struct()

  #     assert {:ok, %WebhookConversation{}} = JobPerformer.send_notification("action", params, 0)
  #   end

  #   test "add the webhook_endpoint metadata to the body request when notifying the endpoint" do
  #     %{url: url} =
  #       webhook_endpoint = insert!(:webhook_endpoint, metadata: %{"source" => "CaptainHook"})

  #     data = %{id: "1"}

  #     params =
  #       CaptainHook.DataWrapper.new(
  #         webhook_endpoint.webhook,
  #         webhook_endpoint.id,
  #         "resource_type",
  #         "resource_id",
  #         data,
  #         []
  #       )
  #       |> Map.from_struct()

  #     encoded_params =
  #       data
  #       |> Map.put(:request_id, params.request_id)
  #       |> Map.merge(webhook_endpoint.metadata)
  #       |> Jason.encode!()

  #     CaptainHook.HttpAdapterMock
  #     |> expect(:post, fn ^url, ^encoded_params, _, _options ->
  #       {:ok, %HTTPoison.Response{status_code: 200, body: "OK"}}
  #     end)

  #     assert {:ok, %WebhookConversation{}} = JobPerformer.send_notification("action", params, 0)
  #   end

  #   test "allow insecure ssl call when the webhook_endpoint's allow_insecure is true when notifying the endpoint" do
  #     %{url: url} = webhook_endpoint = insert!(:webhook_endpoint, allow_insecure: true)

  #     data = %{id: "1"}

  #     params =
  #       CaptainHook.DataWrapper.new(
  #         webhook_endpoint.webhook,
  #         webhook_endpoint.id,
  #         "resource_type",
  #         "resource_id",
  #         data,
  #         []
  #       )
  #       |> Map.from_struct()

  #     CaptainHook.HttpAdapterMock
  #     |> expect(:post, fn ^url, _, _, [{:hackney, [:insecure]} | _] ->
  #       {:ok, %HTTPoison.Response{status_code: 200, body: "OK"}}
  #     end)

  #     assert {:ok, %WebhookConversation{}} = JobPerformer.send_notification("action", params, 0)
  #   end
  # end
end
