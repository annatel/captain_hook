defmodule CaptainHook.WebhookSecrets.WebhookSecretTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  alias CaptainHook.WebhookSecrets.WebhookSecret

  @datetime_1 DateTime.from_naive!(~N[2018-05-24 12:27:48], "Etc/UTC")
  @datetime_2 DateTime.from_naive!(~N[2018-06-24 12:27:48], "Etc/UTC")

  describe "create_changeset/2" do
    test "only permitted_keys are casted" do
      webhook_secret_params = params_for(:webhook_secret)

      changeset =
        WebhookSecret.create_changeset(
          %WebhookSecret{},
          Map.merge(webhook_secret_params, %{new_key: "value"})
        )

      changes_keys = changeset.changes |> Map.keys()

      assert :webhook_endpoint_id in changes_keys
      assert :started_at in changes_keys
      assert :is_main in changes_keys
      refute :ended_at in changes_keys
      refute :new_key in changes_keys
    end

    test "when required params are missing, returns an invalid changeset" do
      changeset = WebhookSecret.create_changeset(%WebhookSecret{}, %{})

      refute changeset.valid?
      assert %{webhook_endpoint_id: ["can't be blank"]} = errors_on(changeset)
      assert %{started_at: ["can't be blank"]} = errors_on(changeset)
      assert %{is_main: ["can't be blank"]} = errors_on(changeset)
    end

    test "when params are valid, return a valid changeset" do
      webhook_secret_params = params_for(:webhook_secret, started_at: @datetime_1)

      changeset = WebhookSecret.create_changeset(%WebhookSecret{}, webhook_secret_params)

      assert changeset.valid?

      assert get_field(changeset, :webhook_endpoint_id) ==
               webhook_secret_params.webhook_endpoint_id

      assert get_field(changeset, :started_at) == @datetime_1
      assert get_field(changeset, :is_main) == webhook_secret_params.is_main
      refute is_nil(get_field(changeset, :secret))
    end
  end

  describe "remove_changeset/2" do
    test "only permitted_keys are casted" do
      webhook_secret = insert!(:webhook_secret)

      webhook_secret_params =
        params_for(:webhook_secret, started_at: @datetime_1, ended_at: @datetime_2)
        |> Map.put(:is_main, false)

      changeset =
        WebhookSecret.remove_changeset(
          webhook_secret,
          Map.merge(webhook_secret_params, %{new_key: "value"})
        )

      changes_keys = changeset.changes |> Map.keys()

      refute :webhook_endpoint_id in changes_keys
      refute :secret in changes_keys
      refute :started_at in changes_keys
      assert :is_main in changes_keys
      assert :ended_at in changes_keys
      refute :new_key in changes_keys
    end

    test "when required params are missing, returns an invalid changeset" do
      webhook_secret = insert!(:webhook_secret)

      changeset = WebhookSecret.remove_changeset(webhook_secret, %{is_main: nil})

      refute changeset.valid?
      assert %{is_main: ["can't be blank"]} = errors_on(changeset)
      assert %{ended_at: ["can't be blank"]} = errors_on(changeset)
    end

    test "when params are invalid, returns an invalid changeset" do
      webhook_secret = insert!(:webhook_secret, started_at: @datetime_2)

      changeset = WebhookSecret.remove_changeset(webhook_secret, %{ended_at: @datetime_1})

      refute changeset.valid?

      assert %{ended_at: ["should be after or equal to started_at"]} = errors_on(changeset)
    end

    test "when params are valid, return a valid changeset" do
      webhook_secret = insert!(:webhook_secret, started_at: @datetime_1)

      changeset = WebhookSecret.remove_changeset(webhook_secret, %{ended_at: @datetime_2})

      assert changeset.valid?
      assert get_field(changeset, :ended_at) == @datetime_2
    end
  end
end
