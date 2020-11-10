defmodule CaptainHookTest do
  use ExUnit.Case, async: false
  use CaptainHook.DataCase

  import Mox

  setup :set_mox_global
  setup :verify_on_exit!

  # describe "notify/4" do
  #   test "when the webhook does not exists, returns an error tuple" do
  #     assert {:error, :no_webhook_endpoint_found} ==
  #              CaptainHook.notify("webhook", "action", {:atom, "id"}, %{})
  #   end

  #   test "when the webhook exists, run for each endpoint a job ordered by their creation date  and return :ok" do
  #     webhook = "webhook"
  #     %{url: url_1} = webhook_endpoint_1 = insert!(:webhook_endpoint, webhook: webhook)
  #     %{url: url_2} = webhook_endpoint_2 = insert!(:webhook_endpoint, webhook: webhook)

  #     CaptainHook.HttpAdapterMock
  #     |> expect(:post, 2, fn
  #       ^url_1, _, _, _options ->
  #         {:ok, %HTTPoison.Response{status_code: 200, body: "OK"}}

  #       ^url_2, _, _, _options ->
  #         {:error, %HTTPoison.Error{reason: :connect_timeout}}
  #     end)

  #     assert :ok == CaptainHook.notify(webhook, "action", {:atom, "id"}, %{})

  #     start_supervised({CaptainHook.Supervisor, [poll_interval: 500]})

  #     :timer.sleep(800)

  #     assert %{data: [webhook_conversation]} =
  #              CaptainHook.WebhookConversations.list_webhook_conversations(
  #                webhook_endpoint_1.webhook,
  #                webhook_endpoint_1
  #              )

  #     assert webhook_conversation.status ==
  #              CaptainHook.WebhookConversations.WebhookConversation.status().success

  #     assert %{data: [webhook_conversation]} =
  #              CaptainHook.WebhookConversations.list_webhook_conversations(
  #                webhook_endpoint_2.webhook,
  #                webhook_endpoint_2
  #              )

  #     assert webhook_conversation.status ==
  #              CaptainHook.WebhookConversations.WebhookConversation.status().failed
  #   end
  # end
end
