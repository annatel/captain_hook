defmodule CaptainHook.WebhookEndpoints.Secrets.WebhookEndpointSecretTest do
  use CaptainHook.DataCase, async: true

  alias CaptainHook.WebhookEndpoints.Secrets.WebhookEndpointSecret

  @datetime_1 DateTime.from_naive!(~N[2018-05-24 12:27:48], "Etc/UTC")
  @datetime_2 DateTime.from_naive!(~N[2018-06-24 12:27:48], "Etc/UTC")

  describe "create_changeset/2" do
    test "only permitted_keys are casted" do
      webhook_endpoint_secret_params =
        params_for(:webhook_endpoint_secret, webhook_endpoint_id: uuid())

      changeset =
        WebhookEndpointSecret.create_changeset(
          %WebhookEndpointSecret{},
          Map.merge(webhook_endpoint_secret_params, %{new_key: "value"})
        )

      changes_keys = changeset.changes |> Map.keys()

      assert :webhook_endpoint_id in changes_keys
      assert :started_at in changes_keys
      assert :is_main in changes_keys
      refute :ended_at in changes_keys
      refute :new_key in changes_keys
    end

    test "when required params are missing, returns an invalid changeset" do
      changeset = WebhookEndpointSecret.create_changeset(%WebhookEndpointSecret{}, %{})

      refute changeset.valid?
      assert %{webhook_endpoint_id: ["can't be blank"]} = errors_on(changeset)
      assert %{started_at: ["can't be blank"]} = errors_on(changeset)
      assert %{is_main: ["can't be blank"]} = errors_on(changeset)
    end

    test "when params are valid, return a valid changeset" do
      webhook_endpoint = insert!(:webhook_endpoint)

      webhook_endpoint_secret_params =
        params_for(:webhook_endpoint_secret,
          webhook_endpoint_id: webhook_endpoint.id,
          started_at: @datetime_1
        )

      changeset =
        WebhookEndpointSecret.create_changeset(
          %WebhookEndpointSecret{},
          webhook_endpoint_secret_params
        )

      assert changeset.valid?

      assert get_field(changeset, :webhook_endpoint_id) ==
               webhook_endpoint_secret_params.webhook_endpoint_id

      assert get_field(changeset, :started_at) == @datetime_1
      assert get_field(changeset, :is_main) == webhook_endpoint_secret_params.is_main
      refute is_nil(get_field(changeset, :secret))
    end
  end

  describe "remove_changeset/2" do
    test "only permitted_keys are casted" do
      webhook_endpoint = insert!(:webhook_endpoint)

      webhook_endpoint_secret =
        insert!(:webhook_endpoint_secret, webhook_endpoint_id: webhook_endpoint.id)

      webhook_endpoint_secret_params =
        params_for(:webhook_endpoint_secret, started_at: @datetime_1, ended_at: @datetime_2)
        |> Map.put(:is_main, false)

      changeset =
        WebhookEndpointSecret.remove_changeset(
          webhook_endpoint_secret,
          Map.merge(webhook_endpoint_secret_params, %{new_key: "value"})
        )

      changes_keys = changeset.changes |> Map.keys()

      refute :webhook_endpoint_id in changes_keys
      refute :secret in changes_keys
      refute :started_at in changes_keys
      assert :is_main in changes_keys
      assert :ended_at in changes_keys
      refute :new_key in changes_keys
    end

    test "when params are valid, return a valid changeset" do
      webhook_endpoint = insert!(:webhook_endpoint)

      webhook_endpoint_secret =
        insert!(:webhook_endpoint_secret,
          webhook_endpoint_id: webhook_endpoint.id,
          started_at: @datetime_1
        )

      changeset =
        WebhookEndpointSecret.remove_changeset(webhook_endpoint_secret, %{ended_at: @datetime_2})

      assert changeset.valid?
      assert get_field(changeset, :ended_at) == @datetime_2
    end

    test "when required params are missing, returns an invalid changeset" do
      webhook_endpoint = insert!(:webhook_endpoint)

      webhook_endpoint_secret =
        insert!(:webhook_endpoint_secret, webhook_endpoint_id: webhook_endpoint.id)

      changeset = WebhookEndpointSecret.remove_changeset(webhook_endpoint_secret, %{is_main: nil})

      refute changeset.valid?
      assert %{is_main: ["can't be blank"]} = errors_on(changeset)
      assert %{ended_at: errors} = errors_on(changeset)
      assert "can't be blank" in errors
    end

    test "when params are invalid, returns an invalid changeset" do
      webhook_endpoint = insert!(:webhook_endpoint)

      webhook_endpoint_secret =
        insert!(:webhook_endpoint_secret,
          webhook_endpoint_id: webhook_endpoint.id,
          started_at: @datetime_2
        )

      changeset =
        WebhookEndpointSecret.remove_changeset(webhook_endpoint_secret, %{ended_at: @datetime_1})

      refute changeset.valid?

      assert %{ended_at: ["should be after or equal to started_at"]} = errors_on(changeset)
    end

    test "when ended_at is after the max expiration time, returns a changeset error" do
      webhook_endpoint = insert!(:webhook_endpoint)

      webhook_endpoint_secret =
        insert!(:webhook_endpoint_secret,
          webhook_endpoint_id: webhook_endpoint.id,
          started_at: utc_now()
        )

      max_expiration_time = utc_now() |> add(7 * 24 * 3600 + 100)

      over_max_expiration_time = max_expiration_time |> add(100)

      webhook_endpoint_secret_params =
        build(:webhook_endpoint_secret, ended_at: over_max_expiration_time) |> params_for()

      changeset =
        WebhookEndpointSecret.remove_changeset(
          webhook_endpoint_secret,
          webhook_endpoint_secret_params
        )

      refute changeset.valid?

      assert %{ended_at: ["should be before or equal to #{max_expiration_time}"]} ==
               errors_on(changeset)
    end
  end
end
