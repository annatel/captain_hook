defmodule CaptainHookTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  import Mox

  setup :verify_on_exit!

  describe "notify/4" do
    test "when the webhook does not exists, returns an error tuple" do
      assert {:error, :no_webhook_endpoint_found} ==
               CaptainHook.notify("webhook", "action", {:atom, "id"}, %{})
    end

    test "when the webhook exists, run for each endpoint a job and return :ok" do
      %{webhook: webhook, id: webhook_endpoint_id_1} = insert(:webhook_endpoint)
      %{id: webhook_endpoint_id_2} = insert(:webhook_endpoint, webhook: webhook)

      queue_name_1 = "#{webhook}_#{webhook_endpoint_id_1}"
      params_1 = CaptainHook.DataWrapper.new(webhook, webhook_endpoint_id_1, :atom, "id", %{}, [])
      queue_name_2 = "#{webhook}_#{webhook_endpoint_id_2}"

      params_2 = CaptainHook.DataWrapper.new(webhook, webhook_endpoint_id_2, :atom, "id", %{}, [])

      action = "action"

      # Mox does not provide a way to test that the same function with the same arity are called only once.
      # When you redifine a mock for the same function with the same arity mox are override
      CaptainHook.QueueMock
      |> expect(:create_job, 2, fn
        ^queue_name_1, ^action, ^params_1, _ -> {:ok, nil}
        ^queue_name_2, ^action, ^params_2, _ -> {:ok, nil}
      end)

      assert :ok == CaptainHook.notify(webhook, "action", {:atom, "id"}, %{})
    end
  end
end
