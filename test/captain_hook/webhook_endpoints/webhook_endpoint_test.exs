defmodule CaptainHook.WebhookEndpoints.WebhookEndpointTest do
  use CaptainHook.DataCase, async: true

  alias CaptainHook.WebhookEndpoints.WebhookEndpoint

  describe "create_changeset/2" do
    test "only permitted_keys are casted" do
      webhook_endpoint_params =
        build(:webhook_endpoint, is_insecure_allowed: true, is_enabled: false)
        |> make_deleted()
        |> params_for()

      changeset =
        WebhookEndpoint.create_changeset(
          %WebhookEndpoint{},
          Map.merge(webhook_endpoint_params, %{new_key: "value"})
        )

      changes_keys = changeset.changes |> Map.keys()

      assert :owner_id in changes_keys
      assert :created_at in changes_keys
      refute :deleted_at in changes_keys
      assert :enabled_notification_patterns in changes_keys
      assert :headers in changes_keys
      assert :is_enabled in changes_keys
      assert :is_insecure_allowed in changes_keys
      assert :livemode in changes_keys
      assert :url in changes_keys
      refute :new_key in changes_keys
    end

    test "when required params are missing, returns an invalid changeset" do
      changeset = WebhookEndpoint.create_changeset(%WebhookEndpoint{}, %{})

      refute changeset.valid?
      assert %{owner_id: ["can't be blank"]} = errors_on(changeset)
      assert %{livemode: ["can't be blank"]} = errors_on(changeset)
      assert %{url: ["can't be blank"]} = errors_on(changeset)
    end

    test "when params are valid, return a valid changeset" do
      %{enabled_notification_patterns: [enabled_notification_pattern]} =
        webhook_endpoint_params = params_for(:webhook_endpoint, is_insecure_allowed: true)

      changeset = WebhookEndpoint.create_changeset(%WebhookEndpoint{}, webhook_endpoint_params)

      assert changeset.valid?
      assert get_field(changeset, :owner_id) == webhook_endpoint_params.owner_id
      assert get_field(changeset, :created_at) == webhook_endpoint_params.created_at

      assert Map.get(hd(get_field(changeset, :enabled_notification_patterns)), :name) ==
               Map.get(enabled_notification_pattern, :name)

      assert get_field(changeset, :headers) == webhook_endpoint_params.headers

      assert get_field(changeset, :is_insecure_allowed) ==
               webhook_endpoint_params.is_insecure_allowed

      assert get_field(changeset, :livemode) == webhook_endpoint_params.livemode

      assert get_field(changeset, :url) == webhook_endpoint_params.url
    end
  end

  describe "update_changeset/2" do
    test "only permitted_keys are casted" do
      webhook_endpoint = insert!(:webhook_endpoint)

      webhook_endpoint_params =
        build(:webhook_endpoint,
          is_insecure_allowed: false,
          headers: %{"key" => "value"}
        )
        |> make_disable()
        |> make_deleted()
        |> params_for()

      changeset =
        WebhookEndpoint.update_changeset(
          webhook_endpoint,
          Map.merge(webhook_endpoint_params, %{
            new_key: "new value",
            is_enable: true,
            is_insecure_allowed: true,
            livemode: false
          })
        )

      changes_keys = changeset.changes |> Map.keys()

      refute :owner_id in changes_keys
      refute :created_at in changes_keys
      refute :deleted_at in changes_keys
      assert :headers in changes_keys
      assert :is_enabled in changes_keys
      assert :is_insecure_allowed in changes_keys
      refute :livemode in changes_keys
      assert :url in changes_keys
      refute :new_key in changes_keys
    end

    test "when params are valid, return a valid changeset" do
      webhook_endpoint = insert!(:webhook_endpoint)

      new_headers = %{"key" => "value"}
      new_url = "new_url"

      changeset =
        WebhookEndpoint.update_changeset(webhook_endpoint, %{
          headers: new_headers,
          is_enabled: !webhook_endpoint.is_enabled,
          is_insecure_allowed: !webhook_endpoint.is_insecure_allowed,
          url: new_url
        })

      assert changeset.valid?
      assert get_field(changeset, :headers) == new_headers
      assert get_field(changeset, :is_enabled) == !webhook_endpoint.is_enabled
      assert get_field(changeset, :is_insecure_allowed) == !webhook_endpoint.is_insecure_allowed
      assert get_field(changeset, :url) == new_url
    end
  end

  describe "remove_changeset/2" do
    test "only permitted_keys are casted" do
      webhook_endpoint = insert!(:webhook_endpoint)

      webhook_endpoint_params =
        build(:webhook_endpoint,
          is_enabled: true,
          is_insecure_allowed: true,
          headers: %{"key" => "value"}
        )
        |> make_deleted()
        |> params_for()

      changeset =
        WebhookEndpoint.remove_changeset(
          webhook_endpoint,
          Map.merge(webhook_endpoint_params, %{
            new_key: "value",
            is_insecure_allowed: true,
            livemode: false
          })
        )

      changes_keys = changeset.changes |> Map.keys()

      refute :owner_id in changes_keys
      refute :created_at in changes_keys
      assert :deleted_at in changes_keys
      refute :headers in changes_keys
      assert :is_enabled in changes_keys
      refute :is_insecure_allowed in changes_keys
      refute :livemode in changes_keys
      refute :url in changes_keys
      refute :new_key in changes_keys
    end

    test "when required params are missing, returns an invalid changeset" do
      webhook_endpoint = insert!(:webhook_endpoint)

      changeset = WebhookEndpoint.remove_changeset(webhook_endpoint, %{})

      refute changeset.valid?
      assert %{deleted_at: ["can't be blank"]} = errors_on(changeset)
    end

    test "when params are invalid, returns an invalid changeset" do
      utc_now = utc_now()
      webhook_endpoint = insert!(:webhook_endpoint, created_at: utc_now)

      changeset =
        WebhookEndpoint.remove_changeset(webhook_endpoint, %{
          deleted_at: utc_now |> add(-1200, :second)
        })

      refute changeset.valid?

      assert %{deleted_at: ["should be after or equal to created_at"]} = errors_on(changeset)
    end

    test "when params are valid, return a valid changeset" do
      deleted_at = utc_now() |> add(1200, :second)

      webhook_endpoint = insert!(:webhook_endpoint)

      changeset = WebhookEndpoint.remove_changeset(webhook_endpoint, %{deleted_at: deleted_at})

      assert changeset.valid?
      assert get_field(changeset, :deleted_at) == deleted_at
      assert get_field(changeset, :is_enabled) == false
    end
  end
end
