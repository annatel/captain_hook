defmodule CaptainHook.WebhookEndpointsTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  alias CaptainHook.WebhookEndpoints

  @datetime_1 DateTime.from_naive!(~N[2018-05-24 12:27:48], "Etc/UTC")
  @datetime_2 DateTime.from_naive!(~N[2018-06-24 12:27:48], "Etc/UTC")

  describe "list_webhook_endpoints/1" do
    test "return webhook_endpoints by webhook identifier" do
      webhook_endpoint_1 = insert(:webhook_endpoint)
      webhook_endpoint_2 = insert(:webhook_endpoint)

      assert [webhook_endpoint_1] ==
               WebhookEndpoints.list_webhook_endpoints(webhook_endpoint_1.webhook)

      assert [webhook_endpoint_2] ==
               WebhookEndpoints.list_webhook_endpoints(webhook_endpoint_2.webhook)
    end
  end

  describe "filter_webhook_endpoints/3" do
    test "returns webhook_endpoints according to the status" do
      assert [] == WebhookEndpoints.filter_webhook_endpoints([], :ongoing, @datetime_1)
      assert [] == WebhookEndpoints.filter_webhook_endpoints([], :ended, @datetime_1)
      assert [] == WebhookEndpoints.filter_webhook_endpoints([], :scheduled, @datetime_1)

      ongoing = build(:webhook_endpoint, started_at: @datetime_1)
      ended = build(:webhook_endpoint, started_at: @datetime_1, ended_at: @datetime_1)
      scheduled = build(:webhook_endpoint, started_at: @datetime_2, ended_at: @datetime_2)

      webhook_endpoints = [ongoing, ended, scheduled]

      assert [^ongoing] =
               WebhookEndpoints.filter_webhook_endpoints(webhook_endpoints, :ongoing, @datetime_1)

      assert [^ended] =
               WebhookEndpoints.filter_webhook_endpoints(webhook_endpoints, :ended, @datetime_1)

      assert [^scheduled] =
               WebhookEndpoints.filter_webhook_endpoints(
                 webhook_endpoints,
                 :scheduled,
                 @datetime_1
               )

      assert [] =
               WebhookEndpoints.filter_webhook_endpoints(
                 webhook_endpoints,
                 :unknown_status,
                 @datetime_1
               )
    end
  end

  describe "get_webhook_endpoint/2" do
    test "when then webhook_endoint's id belongs to the webhook, return the webhook_endpoint" do
      webhook_endpoint_factory = insert(:webhook_endpoint)

      webhook_endpoint =
        WebhookEndpoints.get_webhook_endpoint(
          webhook_endpoint_factory.webhook,
          webhook_endpoint_factory.id
        )

      assert webhook_endpoint.webhook == webhook_endpoint_factory.webhook
      assert webhook_endpoint.id == webhook_endpoint_factory.id
    end

    test "when the webhook_endpoint does not exist, returns nil" do
      webhook_endpoint = build(:webhook_endpoint, id: CaptainHook.Factory.uuid())

      assert is_nil(
               WebhookEndpoints.get_webhook_endpoint(
                 webhook_endpoint.webhook,
                 webhook_endpoint.id
               )
             )
    end

    test "when the webhook_endpoint does not belong to the webhook, returns nil" do
      %{webhook: webhook} = insert(:webhook_endpoint)
      webhook_endpoint = insert(:webhook_endpoint)

      assert is_nil(WebhookEndpoints.get_webhook_endpoint(webhook, webhook_endpoint.id))
    end
  end

  describe "create_webhook_endpoint/2" do
    test "without required params, returns an :error tuple with an invalid changeset" do
      webhook_endpoint_params = params_for(:webhook_endpoint, url: nil)

      assert {:error, changeset} =
               WebhookEndpoints.create_webhook_endpoint(
                 webhook_endpoint_params.webhook,
                 webhook_endpoint_params
               )

      refute changeset.valid?
    end

    test "with valid params, returns the webhook_endpoint" do
      webhook_endpoint_params = params_for(:webhook_endpoint)

      assert {:ok, webhook_endpoint} =
               WebhookEndpoints.create_webhook_endpoint(
                 webhook_endpoint_params.webhook,
                 webhook_endpoint_params
               )

      assert webhook_endpoint.webhook == webhook_endpoint_params.webhook
      assert webhook_endpoint.started_at == webhook_endpoint_params.started_at
      assert webhook_endpoint.url == webhook_endpoint_params.url
      assert webhook_endpoint.metadata == webhook_endpoint_params.metadata
      assert is_nil(webhook_endpoint.ended_at)
    end
  end

  describe "update_webhook_endpoint/2" do
    test "with valid params, update the webhook_endpoint" do
      webhook_endpoint_factory = insert(:webhook_endpoint)

      assert {:ok, webhook_endpoint} =
               WebhookEndpoints.update_webhook_endpoint(webhook_endpoint_factory, %{
                 metadata: %{key: "new_value"}
               })

      assert webhook_endpoint.metadata == %{key: "new_value"}
      assert is_nil(webhook_endpoint.ended_at)
    end
  end

  describe "delete_webhook_endpoint/2" do
    test "with a webhook_endpoint that is ended, raises a FunctionClauseError" do
      webhook_endpoint = insert(:webhook_endpoint, ended_at: @datetime_1)

      assert_raise FunctionClauseError, fn ->
        WebhookEndpoints.delete_webhook_endpoint(webhook_endpoint, @datetime_1)
      end
    end

    test "with an invalid params, returns an invalid changeset" do
      webhook_endpoint = insert(:webhook_endpoint, started_at: @datetime_2)

      assert {:error, changeset} =
               WebhookEndpoints.delete_webhook_endpoint(webhook_endpoint, @datetime_1)

      refute changeset.valid?
    end

    test "with valid params, returns the ended webhook_endpoint" do
      webhook_endpoint_factory = insert(:webhook_endpoint, started_at: @datetime_1)

      assert {:ok, webhook_endpoint} =
               WebhookEndpoints.delete_webhook_endpoint(webhook_endpoint_factory, @datetime_2)

      assert webhook_endpoint.ended_at == @datetime_2
    end
  end
end
