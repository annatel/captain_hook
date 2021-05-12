defmodule CaptainHook.WebhookEndpointsTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  alias CaptainHook.WebhookEndpoints

  @datetime_1 DateTime.from_naive!(~N[2018-05-24 12:27:48], "Etc/UTC")
  @datetime_2 DateTime.from_naive!(~N[2018-06-24 12:27:48], "Etc/UTC")

  describe "list_webhook_endpoints/1" do
    test "returns the list of webhook_endpoints ordered by their started_at ascending" do
      %{id: webhook_endpoint_1_id} = insert!(:webhook_endpoint, started_at: @datetime_1)

      %{id: webhook_endpoint_2_id} = insert!(:webhook_endpoint, started_at: @datetime_2)

      assert [%{id: ^webhook_endpoint_1_id}, %{id: ^webhook_endpoint_2_id}] =
               WebhookEndpoints.list_webhook_endpoints()
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
        [topic: webhook_endpoint.topic],
        [livemode: webhook_endpoint.livemode],
        [ongoing_at: utc_now]
      ]
      |> Enum.each(fn filter ->
        assert [_webhook_endpoint] = WebhookEndpoints.list_webhook_endpoints(filters: filter)
      end)

      [
        [id: uuid()],
        [topic: "topic"],
        [livemode: !webhook_endpoint.livemode],
        [ended_at: DateTime.add(utc_now, -3600, :second)],
        [scheduled_at: DateTime.add(utc_now, 7200, :second)]
      ]
      |> Enum.each(fn filter ->
        assert [] = WebhookEndpoints.list_webhook_endpoints(filters: filter)
      end)
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
    test "when then webhook_endpoint exists, returns the webhook_endpoint" do
      webhook_endpoint_factory = insert!(:webhook_endpoint)

      webhook_endpoint = WebhookEndpoints.get_webhook_endpoint(webhook_endpoint_factory.id)
      assert %WebhookEndpoints.WebhookEndpoint{} = webhook_endpoint
      assert webhook_endpoint.topic == webhook_endpoint_factory.topic
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

      assert webhook_endpoint.topic == webhook_endpoint_factory.topic
      assert webhook_endpoint.id == webhook_endpoint_factory.id
      assert webhook_endpoint.secret == webhook_secret.secret

      [Access.key!(:enabled_notification_types)]
      |> associations_on(webhook_endpoint)
      |> Enum.each(fn assoc ->
        assert assoc |> List.wrap() |> List.first() |> Ecto.assoc_loaded?()
      end)
    end

    test "when the webhook_endpoint does not exist, returns nil" do
      assert is_nil(WebhookEndpoints.get_webhook_endpoint(uuid()))
    end
  end

  describe "get_webhook_endpoint!/2" do
    test "when then webhook_endpoint exists, returns the webhook_endpoint" do
      webhook_endpoint_factory = insert!(:webhook_endpoint)

      assert %WebhookEndpoints.WebhookEndpoint{} =
               WebhookEndpoints.get_webhook_endpoint!(webhook_endpoint_factory.id)
    end

    test "when the webhook_endpoint does not exist, raises a Ecto.NoResultsError" do
      assert_raise Ecto.NoResultsError, fn ->
        WebhookEndpoints.get_webhook_endpoint!(uuid())
      end
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

      assert webhook_endpoint.topic == webhook_endpoint_params.topic
      assert webhook_endpoint.started_at == webhook_endpoint_params.started_at
      assert webhook_endpoint.url == webhook_endpoint_params.url
      assert is_nil(webhook_endpoint.ended_at)

      assert [enabled_notification_type] = webhook_endpoint.enabled_notification_types

      assert enabled_notification_type.name ==
               Map.get(hd(webhook_endpoint_params.enabled_notification_types), :name)

      assert [webhook_secret] = WebhookEndpoints.list_webhook_endpoint_secrets(webhook_endpoint)

      assert webhook_secret.is_main
    end
  end

  describe "update_webhook_endpoint/2" do
    test "with valid params, update the webhook_endpoint" do
      webhook_endpoint_factory = insert!(:webhook_endpoint)

      assert {:ok, webhook_endpoint} =
               WebhookEndpoints.update_webhook_endpoint(webhook_endpoint_factory, %{
                 headers: %{key: "new_value"}
               })

      assert webhook_endpoint.headers == %{key: "new_value"}
      assert is_nil(webhook_endpoint.ended_at)
    end
  end

  describe "delete_webhook_endpoint/2" do
    test "with a webhook_endpoint that is ended, raises a FunctionClauseError" do
      webhook_endpoint = insert!(:webhook_endpoint, ended_at: @datetime_1)

      assert_raise FunctionClauseError, fn ->
        WebhookEndpoints.delete_webhook_endpoint(webhook_endpoint, @datetime_1)
      end
    end

    test "with an invalid params, returns an invalid changeset" do
      webhook_endpoint = insert!(:webhook_endpoint, started_at: @datetime_2)

      assert {:error, changeset} =
               WebhookEndpoints.delete_webhook_endpoint(webhook_endpoint, @datetime_1)

      refute changeset.valid?
    end

    test "with valid params, returns the ended webhook_endpoint" do
      webhook_endpoint_factory = insert!(:webhook_endpoint, started_at: @datetime_1)

      insert!(:webhook_endpoint_secret,
        webhook_endpoint_id: webhook_endpoint_factory.id,
        is_main: true,
        started_at: @datetime_1
      )

      insert!(:webhook_endpoint_secret,
        webhook_endpoint_id: webhook_endpoint_factory.id,
        is_main: false,
        started_at: @datetime_1
      )

      assert {:ok, webhook_endpoint} =
               WebhookEndpoints.delete_webhook_endpoint(webhook_endpoint_factory, @datetime_2)

      assert webhook_endpoint.ended_at == @datetime_2

      assert [] = WebhookEndpoints.list_webhook_endpoint_secrets(webhook_endpoint)
    end
  end

  describe "enable_notification_type/2" do
    test "enable a type of notification, returns the updated webhook_endpoint" do
      %{enabled_notification_types: [notification_type_1_factory]} =
        webhook_endpoint =
        insert!(:webhook_endpoint,
          enabled_notification_types: [
            build(:enabled_notification_type, name: "notification_type_1")
          ]
        )

      assert {:ok, %{enabled_notification_types: enabled_notification_types}} =
               WebhookEndpoints.enable_notification_type(webhook_endpoint, "notification_type_2")

      notification_type_1 =
        enabled_notification_types
        |> Enum.filter(&(&1.name == "notification_type_1"))
        |> List.first()

      assert notification_type_1_factory.id == notification_type_1.id

      assert [_notification_type_2] =
               enabled_notification_types |> Enum.filter(&(&1.name == "notification_type_2"))
    end

    test "enable a list of type of notification, returns the updated webhook_endpoint" do
      webhook_endpoint = insert!(:webhook_endpoint, enabled_notification_types: [])

      assert {:ok, %{enabled_notification_types: enabled_notification_types}} =
               WebhookEndpoints.enable_notification_type(webhook_endpoint, [
                 "notification_type_1",
                 "notification_type_2"
               ])

      assert enabled_notification_types
             |> Enum.map(& &1.name)
             |> Enum.member?("notification_type_1")

      assert enabled_notification_types
             |> Enum.map(& &1.name)
             |> Enum.member?("notification_type_2")
    end

    test "enable an already enabled type of notification, ignore it and returns the webhook_endpoint" do
      %{enabled_notification_types: [enabled_notification_type]} =
        webhook_endpoint =
        insert!(:webhook_endpoint, enabled_notification_types: [build(:enabled_notification_type)])

      assert {:ok, %{enabled_notification_types: enabled_notification_types}} =
               WebhookEndpoints.enable_notification_type(
                 webhook_endpoint,
                 enabled_notification_type.name
               )

      assert Map.get(hd(enabled_notification_types), :name) == enabled_notification_type.name
    end
  end

  describe "disable_notification_type/2" do
    test "disable an enabled notification type, return the updated webhook_endpoint" do
      %{enabled_notification_types: [enabled_notification_type]} =
        webhook_endpoint =
        insert!(:webhook_endpoint, enabled_notification_types: [build(:enabled_notification_type)])

      assert {:ok, %{enabled_notification_types: []}} =
               WebhookEndpoints.disable_notification_type(
                 webhook_endpoint,
                 enabled_notification_type.name
               )

      assert [] = WebhookEndpoints.EnabledNotificationType |> CaptainHook.repo().all()
    end

    test "disable a disabled notification type, ignore it and return the webhook_endpoint" do
    end
  end

  describe "notification_type_enabled?/2" do
    test "when the notification type is enabled, return true" do
      %{enabled_notification_types: [enabled_notification_type]} =
        webhook_endpoint =
        insert!(:webhook_endpoint, enabled_notification_types: [build(:enabled_notification_type)])

      assert WebhookEndpoints.notification_type_enabled?(
               webhook_endpoint,
               enabled_notification_type.name
             )
    end

    test "when the notification type is not enabled, return false" do
      webhook_endpoint = insert!(:webhook_endpoint, enabled_notification_types: [])

      refute WebhookEndpoints.notification_type_enabled?(webhook_endpoint, "notification_type")
    end

    test "when the webhook_endpoint has the wildcard enabled, return true" do
      webhook_endpoint =
        insert!(:webhook_endpoint,
          enabled_notification_types: [build(:enabled_notification_type) |> catch_all_events()]
        )

      assert WebhookEndpoints.notification_type_enabled?(webhook_endpoint, "notification_type")
    end
  end
end
