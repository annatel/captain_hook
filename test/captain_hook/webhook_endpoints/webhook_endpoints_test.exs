defmodule CaptainHook.WebhookEndpointsTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  alias CaptainHook.WebhookEndpoints

  @datetime_1 DateTime.from_naive!(~N[2018-05-24 12:27:48], "Etc/UTC")
  @datetime_2 DateTime.from_naive!(~N[2018-06-24 12:27:48], "Etc/UTC")

  describe "list_webhook_endpoints/1" do
    test "returns the list of webhook_endpoints" do
      insert!(:webhook_endpoint)
      assert [_webhook_endpoint] = WebhookEndpoints.list_webhook_endpoints()
    end

    test "filters" do
      utc_now = utc_now()

      webhook_endpoint =
        insert!(:webhook_endpoint,
          started_at: utc_now,
          ended_at: DateTime.add(utc_now, 3600, :second)
        )

      [
        [id: webhook_endpoint.id],
        [webhook: webhook_endpoint.webhook],
        [livemode: webhook_endpoint.livemode]
      ]
      |> Enum.each(fn filter ->
        assert [_webhook_endpoint] = WebhookEndpoints.list_webhook_endpoints(filters: filter)
      end)

      [
        [id: uuid()],
        [webhook: "webhook"],
        [livemode: !webhook_endpoint.livemode]
      ]
      |> Enum.each(fn filter ->
        assert [] = WebhookEndpoints.list_webhook_endpoints(filters: filter)
      end)

      assert [_webhook_endpoint] =
               WebhookEndpoints.list_webhook_endpoints(filters: [ongoing_at: utc_now])

      assert [] =
               WebhookEndpoints.list_webhook_endpoints(
                 filters: [ended_at: DateTime.add(utc_now, -3600, :second)]
               )

      assert [] =
               WebhookEndpoints.list_webhook_endpoints(
                 filters: [scheduled_at: DateTime.add(utc_now, 7200, :second)]
               )
    end

    test "by default list_webhook_endpoints includes no components" do
      WebhookEndpoints.list_webhook_endpoints()
      webhook_endpoint = insert!(:webhook_endpoint)
      insert!(:webhook_endpoint_secret, webhook_endpoint_id: webhook_endpoint.id)

      assert [webhook_endpoint] = WebhookEndpoints.list_webhook_endpoints()

      assert is_nil(Map.get(webhook_endpoint, :secret))

      [Access.key!(:enabled_notification_types)]
      |> associations_on(webhook_endpoint)
      |> Enum.each(fn assoc ->
        refute assoc |> List.wrap() |> List.first() |> Ecto.assoc_loaded?()
      end)
    end

    test "with includes, returns included fields" do
      webhook_endpoint = insert!(:webhook_endpoint)
      insert!(:webhook_endpoint_secret, webhook_endpoint_id: webhook_endpoint.id)

      assert [webhook_endpoint] =
               WebhookEndpoints.list_webhook_endpoints(
                 includes: [:enabled_notification_types, :secret]
               )

      refute is_nil(Map.get(webhook_endpoint, :secret))

      [Access.key!(:enabled_notification_types)]
      |> associations_on(webhook_endpoint)
      |> Enum.each(fn assoc ->
        assert assoc |> List.wrap() |> List.first() |> Ecto.assoc_loaded?()
      end)
    end
  end

  describe "get_webhook_endpoint/2" do
    test "when then webhook_endpoint exists, return the webhook_endpoint" do
      webhook_endpoint_factory = insert!(:webhook_endpoint)

      webhook_endpoint = WebhookEndpoints.get_webhook_endpoint(webhook_endpoint_factory.id)
      assert %WebhookEndpoints.WebhookEndpoint{} = webhook_endpoint
      assert webhook_endpoint.webhook == webhook_endpoint_factory.webhook
      assert webhook_endpoint.id == webhook_endpoint_factory.id
      assert is_nil(webhook_endpoint.secret)
    end

    test "with includes, return the webhook_endpoint with the included fields" do
      webhook_endpoint_factory = insert!(:webhook_endpoint)

      webhook_secret =
        insert!(:webhook_endpoint_secret, webhook_endpoint_id: webhook_endpoint_factory.id)

      webhook_endpoint =
        WebhookEndpoints.get_webhook_endpoint(webhook_endpoint_factory.id,
          includes: [:enabled_notification_types, :secret]
        )

      assert webhook_endpoint.webhook == webhook_endpoint_factory.webhook
      assert webhook_endpoint.id == webhook_endpoint_factory.id
      assert webhook_endpoint.secret == webhook_secret.secret

      [Access.key!(:enabled_notification_types)]
      |> associations_on(webhook_endpoint)
      |> Enum.each(fn assoc ->
        assert assoc |> List.wrap() |> List.first() |> Ecto.assoc_loaded?()
      end)
    end

    test "when the webhook_endpoint does not exist, returns nil" do
      webhook_endpoint = build(:webhook_endpoint, id: CaptainHook.Factory.uuid())

      assert is_nil(WebhookEndpoints.get_webhook_endpoint(webhook_endpoint.id))
    end
  end

  describe "create_webhook_endpoint/2" do
    test "without required params, returns an :error tuple with an invalid changeset" do
      webhook_endpoint_params = params_for(:webhook_endpoint, url: nil)

      assert {:error, changeset} =
               WebhookEndpoints.create_webhook_endpoint(webhook_endpoint_params)

      refute changeset.valid?
    end

    test "with valid params, returns the webhook_endpoint" do
      webhook_endpoint_params = params_for(:webhook_endpoint)

      assert {:ok, webhook_endpoint} =
               WebhookEndpoints.create_webhook_endpoint(webhook_endpoint_params)

      assert webhook_endpoint.webhook == webhook_endpoint_params.webhook
      assert webhook_endpoint.started_at == webhook_endpoint_params.started_at
      assert webhook_endpoint.url == webhook_endpoint_params.url
      assert webhook_endpoint.metadata == webhook_endpoint_params.metadata
      assert is_nil(webhook_endpoint.ended_at)

      assert [webhook_secret] =
               webhook_endpoint |> CaptainHook.WebhookSecrets.list_webhook_endpoint_secrets()

      assert webhook_secret.is_main
    end
  end

  # describe "update_webhook_endpoint/2" do
  #   test "with valid params, update the webhook_endpoint" do
  #     webhook_endpoint_factory = insert!(:webhook_endpoint)

  #     assert {:ok, webhook_endpoint} =
  #              WebhookEndpoints.update_webhook_endpoint(webhook_endpoint_factory, %{
  #                metadata: %{key: "new_value"}
  #              })

  #     assert webhook_endpoint.metadata == %{key: "new_value"}
  #     assert is_nil(webhook_endpoint.ended_at)
  #   end
  # end

  # describe "delete_webhook_endpoint/2" do
  #   test "with a webhook_endpoint that is ended, raises a FunctionClauseError" do
  #     webhook_endpoint = insert!(:webhook_endpoint, ended_at: @datetime_1)

  #     assert_raise FunctionClauseError, fn ->
  #       WebhookEndpoints.delete_webhook_endpoint(webhook_endpoint, @datetime_1)
  #     end
  #   end

  #   test "with an invalid params, returns an invalid changeset" do
  #     webhook_endpoint = insert!(:webhook_endpoint, started_at: @datetime_2)

  #     assert {:error, changeset} =
  #              WebhookEndpoints.delete_webhook_endpoint(webhook_endpoint, @datetime_1)

  #     refute changeset.valid?
  #   end

  #   test "with valid params, returns the ended webhook_endpoint" do
  #     webhook_endpoint_factory = insert!(:webhook_endpoint, started_at: @datetime_1)

  #     insert!(:webhook_secret,
  #       webhook_endpoint_id: webhook_endpoint_factory.id,
  #       is_main: true,
  #       started_at: @datetime_1
  #     )

  #     insert!(:webhook_secret,
  #       webhook_endpoint_id: webhook_endpoint_factory.id,
  #       is_main: false,
  #       started_at: @datetime_1
  #     )

  #     assert {:ok, webhook_endpoint} =
  #              WebhookEndpoints.delete_webhook_endpoint(webhook_endpoint_factory, @datetime_2)

  #     assert webhook_endpoint.ended_at == @datetime_2

  #     assert [webhook_secret_1, webhook_secret_2] =
  #              webhook_endpoint
  #              |> CaptainHook.WebhookSecrets.list_webhook_secrets(:ended, @datetime_2)

  #     assert webhook_secret_1.ended_at == @datetime_2
  #     assert webhook_secret_2.ended_at == @datetime_2
  #   end
  # end
end
