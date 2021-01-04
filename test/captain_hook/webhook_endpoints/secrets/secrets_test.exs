defmodule CaptainHook.WebhookEndpoint.SecretsTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  alias CaptainHook.WebhookEndpoints.Secrets
  alias CaptainHook.WebhookEndpoints.Secrets.WebhookEndpointSecret

  @datetime_1 DateTime.from_naive!(~N[2018-05-24 12:27:48], "Etc/UTC")
  @datetime_2 DateTime.from_naive!(~N[2018-06-24 12:27:48], "Etc/UTC")

  describe "list_webhook_endpoint_secrets/3" do
    test "return the list of ongoing webhook_endpoint_secrets of a webhook_endpoint" do
      webhook_endpoint = insert!(:webhook_endpoint)

      ongoing =
        insert!(:webhook_endpoint_secret,
          webhook_endpoint_id: webhook_endpoint.id,
          started_at: @datetime_1
        )

      _ended =
        insert!(:webhook_endpoint_secret,
          webhook_endpoint_id: webhook_endpoint.id,
          started_at: @datetime_1,
          ended_at: @datetime_1
        )

      _scheduled =
        insert!(:webhook_endpoint_secret,
          webhook_endpoint_id: webhook_endpoint.id,
          started_at: @datetime_2,
          ended_at: @datetime_2
        )

      assert [^ongoing] = Secrets.list_webhook_endpoint_secrets(webhook_endpoint)
    end
  end

  describe "create_webhook_endpoint_secret/2" do
    test "when a main webhook_endpoint_secret already exists, returns an error tuple with an invalid changeset" do
      webhook_endpoint = insert!(:webhook_endpoint)

      insert!(:webhook_endpoint_secret, webhook_endpoint_id: webhook_endpoint.id, is_main: true)

      assert {:error, changeset} =
               Secrets.create_webhook_endpoint_secret(webhook_endpoint, utc_now())

      refute changeset.valid?
      assert %{is_main: ["already exists"]} = errors_on(changeset)
    end

    test "with valid params, returns the webhook_endpoint_secret" do
      webhook_endpoint = insert!(:webhook_endpoint)

      assert {:ok, %WebhookEndpointSecret{} = webhook_endpoint_secret} =
               Secrets.create_webhook_endpoint_secret(webhook_endpoint, utc_now())

      assert webhook_endpoint_secret.webhook_endpoint_id == webhook_endpoint.id
    end
  end

  describe "remove_webhook_endpoint_secret/2" do
    test "when params are invalid, returns an error tuple with an invalid changeset" do
      webhook_endpoint = insert!(:webhook_endpoint)

      webhook_endpoint_secret =
        insert!(:webhook_endpoint_secret,
          webhook_endpoint_id: webhook_endpoint.id,
          started_at: @datetime_2
        )

      assert {:error, changeset} =
               Secrets.remove_webhook_endpoint_secret(webhook_endpoint_secret, @datetime_1)

      refute changeset.valid?
    end

    test "whith valid params, remove the webhook_endpoint_secret" do
      webhook_endpoint = insert!(:webhook_endpoint)

      webhook_endpoint_secret =
        insert!(:webhook_endpoint_secret, webhook_endpoint_id: webhook_endpoint.id)

      ended_at = DateTime.utc_now() |> DateTime.truncate(:second)

      assert {:ok, %WebhookEndpointSecret{} = webhook_endpoint_secret} =
               Secrets.remove_webhook_endpoint_secret(webhook_endpoint_secret, ended_at)

      assert webhook_endpoint_secret.ended_at == ended_at
    end
  end

  describe "roll_webhook_endpoint_secret/1" do
    test "when rolling the webhook_endpoint_secret, closes the main webhook_endpoint_secret if exists, creates a new one and return it" do
      webhook_endpoint = insert!(:webhook_endpoint)

      webhook_endpoint_secret =
        insert!(:webhook_endpoint_secret, webhook_endpoint_id: webhook_endpoint.id)

      rolling_datetime = utc_now() |> DateTime.add(2 * 3600)

      assert {:ok, %WebhookEndpointSecret{} = new_webhook_endpoint_secret} =
               Secrets.roll_webhook_endpoint_secret(webhook_endpoint, rolling_datetime)

      webhook_endpoint_secret = CaptainHook.TestRepo.reload!(webhook_endpoint_secret)

      assert new_webhook_endpoint_secret.id != webhook_endpoint_secret.id
      assert new_webhook_endpoint_secret.secret != webhook_endpoint_secret.secret
      assert new_webhook_endpoint_secret.started_at != rolling_datetime

      assert_in_delta DateTime.to_unix(new_webhook_endpoint_secret.started_at),
                      DateTime.to_unix(DateTime.utc_now()),
                      100

      assert new_webhook_endpoint_secret.is_main
      assert is_nil(new_webhook_endpoint_secret.ended_at)

      assert webhook_endpoint_secret.ended_at == rolling_datetime
      refute webhook_endpoint_secret.is_main
    end

    test "when rolling with a ended datetime that is more than 24 hours, return an error tuple with a invalid changeset" do
      webhook_endpoint = insert!(:webhook_endpoint)
      insert!(:webhook_endpoint_secret, webhook_endpoint_id: webhook_endpoint.id)

      assert {:error, %Ecto.Changeset{} = changeset} =
               Secrets.roll_webhook_endpoint_secret(
                 webhook_endpoint,
                 utc_now() |> add(8 * 24 * 3600)
               )

      refute changeset.valid?
    end
  end

  describe "generate_secret/1" do
    test "generate secret returns a secret prefixed with the @secret_prefix value" do
      generated_secret = Secrets.generate_secret()
      [prefix, secret] = generated_secret |> String.split("_")
      assert prefix == "whsec"
      assert String.length(secret) == 32
    end
  end
end
