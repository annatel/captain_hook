defmodule CaptainHook.WebhookEndpointsTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  alias CaptainHook.WebhookEndpoints

  @notification_pattern_wildcard Application.get_env(
                                   :captain_hook,
                                   :notification_pattern_wildcard
                                 )
  describe "list_webhook_endpoints/1" do
    test "list_webhook_endpoints" do
      %{id: id_1} = insert!(:webhook_endpoint, created_at: utc_now())
      %{id: id_2} = insert!(:webhook_endpoint, created_at: utc_now() |> add(1200, :second))

      assert [%{id: ^id_2}, %{id: ^id_1}] = WebhookEndpoints.list_webhook_endpoints()
      assert [%{id: ^id_1}] = WebhookEndpoints.list_webhook_endpoints(filters: [id: id_1])
    end
  end

  describe "paginate_webhook_endpoints/1" do
    test "returns the list of webhook_endpoints ordered by their id descending" do
      %{id: id1} = insert!(:webhook_endpoint, created_at: utc_now())
      %{id: id2} = insert!(:webhook_endpoint, created_at: utc_now() |> add(1200, :second))

      assert %{data: [%{id: ^id2}, %{id: ^id1}], page_number: 1, page_size: 100, total: 2} =
               WebhookEndpoints.paginate_webhook_endpoints()

      assert %{data: [], page_number: 2, page_size: 100, total: 2} =
               WebhookEndpoints.paginate_webhook_endpoints(100, 2)
    end

    test "filters" do
      webhook_endpoint = insert!(:webhook_endpoint)

      [
        [id: webhook_endpoint.id],
        [owner_id: webhook_endpoint.owner_id],
        [livemode: webhook_endpoint.livemode]
      ]
      |> Enum.each(fn filter ->
        assert %{data: [_webhook_endpoint], total: 1} =
                 WebhookEndpoints.paginate_webhook_endpoints(100, 1, filters: filter)
      end)

      [
        [id: shortcode_uuid("we")],
        [owner_id: uuid()],
        [livemode: !webhook_endpoint.livemode]
      ]
      |> Enum.each(fn filter ->
        assert %{data: []} = WebhookEndpoints.paginate_webhook_endpoints(100, 1, filters: filter)
      end)
    end

    test "soft delete" do
      %{id: id} = insert!(:webhook_endpoint, created_at: utc_now())

      %{id: soft_deleted_id} =
        build(:webhook_endpoint, created_at: utc_now() |> add(1200, :second))
        |> make_deleted()
        |> insert!()

      %{data: [%{id: ^id}], total: 1} = WebhookEndpoints.paginate_webhook_endpoints(100, 1)

      %{data: [%{id: ^soft_deleted_id}, %{id: ^id}], total: 2} =
        WebhookEndpoints.paginate_webhook_endpoints(100, 1, filters: [with_trashed: true])

      %{data: [%{id: ^soft_deleted_id}], total: 1} =
        WebhookEndpoints.paginate_webhook_endpoints(100, 1, filters: [only_trashed: true])
    end

    test "includes" do
      webhook_endpoint = insert!(:webhook_endpoint)
      insert!(:webhook_endpoint_secret, webhook_endpoint_id: webhook_endpoint.id)

      assert %{data: [webhook_endpoint]} = WebhookEndpoints.paginate_webhook_endpoints()
      assert is_nil(Map.get(webhook_endpoint, :secret))
      assert Ecto.assoc_loaded?(webhook_endpoint.enabled_notification_patterns)

      assert %{data: [webhook_endpoint]} =
               WebhookEndpoints.paginate_webhook_endpoints(100, 1, includes: [:secret])

      refute is_nil(webhook_endpoint.secret)
      assert Ecto.assoc_loaded?(webhook_endpoint.enabled_notification_patterns)
    end
  end

  describe "get_webhook_endpoint/2" do
    test "when then webhook_endpoint exists, returns the webhook_endpoint" do
      webhook_endpoint_factory = insert!(:webhook_endpoint)

      webhook_endpoint = WebhookEndpoints.get_webhook_endpoint(webhook_endpoint_factory.id)
      assert %WebhookEndpoints.WebhookEndpoint{} = webhook_endpoint
      assert webhook_endpoint.owner_id == webhook_endpoint_factory.owner_id
      assert webhook_endpoint.id == webhook_endpoint_factory.id
      assert is_nil(webhook_endpoint.secret)
    end

    test "with includes, return the webhook_endpoint with the included fields" do
      webhook_endpoint_factory = insert!(:webhook_endpoint)

      webhook_secret =
        insert!(:webhook_endpoint_secret, webhook_endpoint_id: webhook_endpoint_factory.id)

      webhook_endpoint =
        WebhookEndpoints.get_webhook_endpoint(webhook_endpoint_factory.id,
          includes: [:enabled_notification_patterns, :secret]
        )

      assert webhook_endpoint.owner_id == webhook_endpoint_factory.owner_id
      assert webhook_endpoint.id == webhook_endpoint_factory.id
      assert webhook_endpoint.secret == webhook_secret.secret
      assert Ecto.assoc_loaded?(webhook_endpoint.enabled_notification_patterns)
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

      assert webhook_endpoint.owner_id == webhook_endpoint_params.owner_id
      assert webhook_endpoint.created_at == webhook_endpoint_params.created_at
      assert webhook_endpoint.url == webhook_endpoint_params.url
      assert is_nil(webhook_endpoint.deleted_at)

      assert [enabled_notification_pattern] = webhook_endpoint.enabled_notification_patterns

      assert enabled_notification_pattern.pattern ==
               Map.get(hd(webhook_endpoint_params.enabled_notification_patterns), :pattern)

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
      assert is_nil(webhook_endpoint.deleted_at)
    end
  end

  describe "delete_webhook_endpoint/2" do
    test "with a webhook_endpoint that is soft deleted, raises a FunctionClauseError" do
      webhook_endpoint = build(:webhook_endpoint) |> make_deleted() |> insert!()

      assert_raise FunctionClauseError, fn ->
        WebhookEndpoints.delete_webhook_endpoint(webhook_endpoint, utc_now())
      end
    end

    test "with an invalid params, returns an invalid changeset" do
      utc_now = utc_now()
      webhook_endpoint = build(:webhook_endpoint, created_at: utc_now)

      assert {:error, changeset} =
               WebhookEndpoints.delete_webhook_endpoint(
                 webhook_endpoint,
                 utc_now |> add(-1200, :second)
               )

      refute changeset.valid?
    end

    test "with valid params, returns the ended webhook_endpoint" do
      webhook_endpoint_factory = insert!(:webhook_endpoint)

      insert!(:webhook_endpoint_secret,
        webhook_endpoint_id: webhook_endpoint_factory.id,
        is_main: true
      )

      insert!(:webhook_endpoint_secret,
        webhook_endpoint_id: webhook_endpoint_factory.id,
        is_main: false
      )

      delete_at = utc_now()

      assert {:ok, webhook_endpoint} =
               WebhookEndpoints.delete_webhook_endpoint(webhook_endpoint_factory, delete_at)

      assert webhook_endpoint.deleted_at == delete_at

      assert [] = WebhookEndpoints.list_webhook_endpoint_secrets(webhook_endpoint)
    end
  end

  describe "enable_notification_pattern/2" do
    test "enable a type of notification, returns the updated webhook_endpoint" do
      %{enabled_notification_patterns: [notification_ref_1_factory]} =
        webhook_endpoint =
        insert!(:webhook_endpoint,
          enabled_notification_patterns: [
            build(:enabled_notification_pattern, pattern: "notification_ref_1")
          ]
        )

      assert {:ok, %{enabled_notification_patterns: enabled_notification_patterns}} =
               WebhookEndpoints.enable_notification_pattern(
                 webhook_endpoint,
                 "notification_ref_2"
               )

      notification_ref_1 =
        enabled_notification_patterns
        |> Enum.filter(&(&1.pattern == "notification_ref_1"))
        |> List.first()

      assert notification_ref_1_factory.id == notification_ref_1.id

      assert [_notification_ref_2] =
               enabled_notification_patterns
               |> Enum.filter(&(&1.pattern == "notification_ref_2"))
    end

    test "enable a list of type of notification, returns the updated webhook_endpoint" do
      webhook_endpoint = insert!(:webhook_endpoint, enabled_notification_patterns: [])

      assert {:ok, %{enabled_notification_patterns: enabled_notification_patterns}} =
               WebhookEndpoints.enable_notification_pattern(webhook_endpoint, [
                 "notification_ref_1",
                 "notification_ref_2"
               ])

      assert enabled_notification_patterns
             |> Enum.map(& &1.pattern)
             |> Enum.member?("notification_ref_1")

      assert enabled_notification_patterns
             |> Enum.map(& &1.pattern)
             |> Enum.member?("notification_ref_2")
    end

    test "enable an already enabled type of notification, ignore it and returns the webhook_endpoint" do
      %{enabled_notification_patterns: [enabled_notification_pattern]} =
        webhook_endpoint =
        insert!(:webhook_endpoint,
          enabled_notification_patterns: [build(:enabled_notification_pattern)]
        )

      assert {:ok, %{enabled_notification_patterns: enabled_notification_patterns}} =
               WebhookEndpoints.enable_notification_pattern(
                 webhook_endpoint,
                 enabled_notification_pattern.pattern
               )

      assert Map.get(hd(enabled_notification_patterns), :pattern) ==
               enabled_notification_pattern.pattern
    end
  end

  describe "disable_notification_pattern/2" do
    test "disable an enabled notification type, return the updated webhook_endpoint" do
      %{
        enabled_notification_patterns: [
          enabled_notification_pattern_1,
          %{id: id2} = _enabled_notification_pattern_2
        ]
      } =
        webhook_endpoint =
        insert!(:webhook_endpoint,
          enabled_notification_patterns: [
            build(:enabled_notification_pattern),
            build(:enabled_notification_pattern)
          ]
        )

      assert {:ok,
              %{enabled_notification_patterns: [%{id: ^id2} = _enabled_notification_pattern_2]}} =
               WebhookEndpoints.disable_notification_pattern(
                 webhook_endpoint,
                 enabled_notification_pattern_1.pattern
               )

      assert [_enabled_notification_pattern] =
               WebhookEndpoints.EnabledNotificationPattern |> CaptainHook.repo().all()
    end

    test "disable a disabled notification type, ignore it and return the webhook_endpoint" do
      enabled_notification_pattern = build(:enabled_notification_pattern)

      %{enabled_notification_patterns: [_]} =
        webhook_endpoint =
        insert!(:webhook_endpoint,
          enabled_notification_patterns: [build(:enabled_notification_pattern)]
        )

      assert {:ok, %{enabled_notification_patterns: [_]}} =
               WebhookEndpoints.disable_notification_pattern(
                 webhook_endpoint,
                 enabled_notification_pattern.pattern
               )
    end
  end

  describe "notification_ref_enabled?/2" do
    test "when the notification type is enabled, return true" do
      %{enabled_notification_patterns: [enabled_notification_pattern]} =
        webhook_endpoint =
        insert!(:webhook_endpoint,
          enabled_notification_patterns: [build(:enabled_notification_pattern)]
        )

      assert WebhookEndpoints.notification_ref_enabled?(
               webhook_endpoint,
               enabled_notification_pattern.pattern
             )
    end

    test "when the notification type is enabled with wildcard matching, return true " do
      webhook_endpoint =
        insert!(:webhook_endpoint,
          enabled_notification_patterns: [
            build(:enabled_notification_pattern,
              pattern: "a.b.#{@notification_pattern_wildcard}"
            ),
            build(:enabled_notification_pattern,
              pattern: "c.e"
            )
          ]
        )

      assert WebhookEndpoints.notification_ref_enabled?(
               webhook_endpoint,
               "a.b.c"
             )
    end

    test "when the notification type is not enabled, return false " do
      webhook_endpoint =
        insert!(:webhook_endpoint,
          enabled_notification_patterns: [
            build(:enabled_notification_pattern,
              pattern:
                "a.b.#{@notification_pattern_wildcard}.d.#{@notification_pattern_wildcard}.f.#{@notification_pattern_wildcard}"
            ),
            build(:enabled_notification_pattern,
              pattern: "a.b"
            )
          ]
        )

      refute WebhookEndpoints.notification_ref_enabled?(
               webhook_endpoint,
               "a.c"
             )
    end

    test "when enabled_notification_patterns list is empty, return false" do
      webhook_endpoint = insert!(:webhook_endpoint, enabled_notification_patterns: [])

      refute WebhookEndpoints.notification_ref_enabled?(webhook_endpoint, "notification_type")
    end

    test "when the webhook_endpoint has the wildcard enabled, return true" do
      webhook_endpoint =
        insert!(:webhook_endpoint,
          enabled_notification_patterns: [
            build(:enabled_notification_pattern) |> catch_all_events()
          ]
        )

      assert WebhookEndpoints.notification_ref_enabled?(webhook_endpoint, "notification_type")
    end
  end
end
