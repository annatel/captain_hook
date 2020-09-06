defmodule CaptainHook.WebhookEndpoints.WebhookEndpointTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  alias CaptainHook.WebhookEndpoints.WebhookEndpoint

  @datetime_1 DateTime.from_naive!(~N[2018-05-24 12:27:48], "Etc/UTC")
  @datetime_2 DateTime.from_naive!(~N[2018-06-24 12:27:48], "Etc/UTC")

  describe "create_changeset/2" do
    test "only permitted_keys are casted" do
      webhook_endpoint_params = params_for(:webhook_endpoint)

      changeset =
        WebhookEndpoint.create_changeset(
          %WebhookEndpoint{},
          Map.merge(webhook_endpoint_params, %{new_key: "value"})
        )

      changes_keys = changeset.changes |> Map.keys()

      assert :webhook in changes_keys
      assert :started_at in changes_keys
      assert :url in changes_keys
      assert :metadata in changes_keys
      assert :headers in changes_keys
      refute :ended_at in changes_keys
      refute :new_key in changes_keys
    end

    test "when required params are missing, returns an invalid changeset" do
      changeset = WebhookEndpoint.create_changeset(%WebhookEndpoint{}, %{})

      refute changeset.valid?
      assert %{webhook: ["can't be blank"]} = errors_on(changeset)
      assert %{started_at: ["can't be blank"]} = errors_on(changeset)
      assert %{url: ["can't be blank"]} = errors_on(changeset)
    end

    test "when params are valid, return a valid changeset" do
      webhook_endpoint_params = params_for(:webhook_endpoint, started_at: @datetime_1)

      changeset = WebhookEndpoint.create_changeset(%WebhookEndpoint{}, webhook_endpoint_params)

      assert changeset.valid?
      assert get_field(changeset, :webhook) == webhook_endpoint_params.webhook
      assert get_field(changeset, :started_at) == @datetime_1
      assert get_field(changeset, :url) == webhook_endpoint_params.url
      assert get_field(changeset, :metadata) == webhook_endpoint_params.metadata
      assert get_field(changeset, :headers) == webhook_endpoint_params.headers
    end
  end

  describe "update_changeset/2" do
    test "only permitted_keys are casted" do
      webhook_endpoint = insert(:webhook_endpoint)

      webhook_endpoint_params =
        params_for(:webhook_endpoint,
          started_at: @datetime_1,
          ended_at: @datetime_2,
          metadata: %{key: "value"},
          headers: %{"Authorization" => "Basic bG9naW46cGFzc3dvcmQ="}
        )

      changeset =
        WebhookEndpoint.update_changeset(
          webhook_endpoint,
          Map.merge(webhook_endpoint_params, %{new_key: "new value"})
        )

      changes_keys = changeset.changes |> Map.keys()

      refute :webhook in changes_keys
      refute :started_at in changes_keys
      refute :url in changes_keys
      assert :metadata in changes_keys
      assert :headers in changes_keys
      refute :ended_at in changes_keys
      refute :new_key in changes_keys
    end

    test "when params are valid, return a valid changeset" do
      webhook_endpoint = insert(:webhook_endpoint)

      new_metadata = %{key: "value"}
      new_headers = %{"Authorization" => "Basic bG9naW46cGFzc3dvcmQ="}

      changeset =
        WebhookEndpoint.update_changeset(webhook_endpoint, %{
          metadata: new_metadata,
          headers: new_headers
        })

      assert changeset.valid?
      assert get_field(changeset, :metadata) == new_metadata
      assert get_field(changeset, :headers) == new_headers
    end
  end

  describe "remove_changeset/2" do
    test "only permitted_keys are casted" do
      webhook_endpoint = insert(:webhook_endpoint)

      webhook_endpoint_params =
        params_for(:webhook_endpoint,
          started_at: @datetime_1,
          ended_at: @datetime_2,
          metadata: %{key: "value"}
        )

      changeset =
        WebhookEndpoint.remove_changeset(
          webhook_endpoint,
          Map.merge(webhook_endpoint_params, %{new_key: "value"})
        )

      changes_keys = changeset.changes |> Map.keys()

      refute :webhook in changes_keys
      refute :started_at in changes_keys
      refute :url in changes_keys
      refute :metadata in changes_keys
      refute :headers in changes_keys
      assert :ended_at in changes_keys
      refute :new_key in changes_keys
    end

    test "when required params are missing, returns an invalid changeset" do
      webhook_endpoint = insert(:webhook_endpoint)

      changeset = WebhookEndpoint.remove_changeset(webhook_endpoint, %{})

      refute changeset.valid?
      assert %{ended_at: ["can't be blank"]} = errors_on(changeset)
    end

    test "when params are invalid, returns an invalid changeset" do
      webhook_endpoint = insert(:webhook_endpoint, started_at: @datetime_2)

      changeset = WebhookEndpoint.remove_changeset(webhook_endpoint, %{ended_at: @datetime_1})

      refute changeset.valid?

      assert %{ended_at: ["should be after or equal to started_at"]} = errors_on(changeset)
    end

    test "when params are valid, return a valid changeset" do
      webhook_endpoint = insert(:webhook_endpoint, started_at: @datetime_1)

      changeset = WebhookEndpoint.remove_changeset(webhook_endpoint, %{ended_at: @datetime_2})

      assert changeset.valid?
      assert get_field(changeset, :ended_at) == @datetime_2
    end
  end
end
