defmodule CaptainHook.WebhookSecretsTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  alias CaptainHook.WebhookSecrets
  alias CaptainHook.WebhookSecrets.WebhookSecret

  @datetime_1 DateTime.from_naive!(~N[2018-05-24 12:27:48], "Etc/UTC")
  @datetime_2 DateTime.from_naive!(~N[2018-06-24 12:27:48], "Etc/UTC")

  describe "filter_webhook_secrets/3" do
    test "returns webhook_secrets according to the status" do
      assert [] == WebhookSecrets.filter_webhook_secrets([], :ongoing, @datetime_1)
      assert [] == WebhookSecrets.filter_webhook_secrets([], :ended, @datetime_1)
      assert [] == WebhookSecrets.filter_webhook_secrets([], :scheduled, @datetime_1)

      ongoing = build(:webhook_endpoint, started_at: @datetime_1)
      ended = build(:webhook_endpoint, started_at: @datetime_1, ended_at: @datetime_1)
      scheduled = build(:webhook_endpoint, started_at: @datetime_2, ended_at: @datetime_2)

      webhook_secrets = [ongoing, ended, scheduled]

      assert [^ongoing] =
               WebhookSecrets.filter_webhook_secrets(webhook_secrets, :ongoing, @datetime_1)

      assert [^ended] =
               WebhookSecrets.filter_webhook_secrets(webhook_secrets, :ended, @datetime_1)

      assert [^scheduled] =
               WebhookSecrets.filter_webhook_secrets(
                 webhook_secrets,
                 :scheduled,
                 @datetime_1
               )

      assert [] =
               WebhookSecrets.filter_webhook_secrets(
                 webhook_secrets,
                 :unknown_status,
                 @datetime_1
               )
    end
  end

  describe "create_webhook_secret/2" do
    test "when a main webhook_secret already exists, returns an error tuple with an invalid changeset" do
      webhook_endpoint = insert!(:webhook_endpoint)

      insert!(:webhook_secret, webhook_endpoint_id: webhook_endpoint.id, main?: true)

      assert {:error, changeset} =
               WebhookSecrets.create_webhook_secret(webhook_endpoint, utc_now())

      refute changeset.valid?
      assert %{main?: ["already exists"]} = errors_on(changeset)
    end

    test "with valid params, returns the webhook_secret" do
      webhook_endpoint = insert!(:webhook_endpoint)

      assert {:ok, %WebhookSecret{} = webhook_secret} =
               WebhookSecrets.create_webhook_secret(webhook_endpoint, utc_now())

      assert webhook_secret.webhook_endpoint_id == webhook_endpoint.id
    end
  end

  describe "generate_secret/1" do
    test "generate secret returns a secret prefixed with the @secret_prefix value" do
      generated_secret = WebhookSecrets.generate_secret()
      [prefix, secret] = generated_secret |> String.split("_")
      assert prefix == "whsec"
      assert String.length(secret) == 32
    end

    test "generated secret contains the prefix separator only once" do
      generated_secret = WebhookSecrets.generate_secret()
      assert [_prefix, _secret] = generated_secret |> String.split("_")
    end
  end

  describe "roll/1" do
    test "when rolling the webhook_secret, closes the main webhook_secret if exists, creates a new one and return it" do
      webhook_endpoint = insert!(:webhook_endpoint)
      webhook_secret = insert!(:webhook_secret, webhook_endpoint_id: webhook_endpoint.id)
      rolling_datetime = utc_now() |> DateTime.add(2 * 3600)

      assert {:ok, %WebhookSecret{} = new_webhook_secret} =
               WebhookSecrets.roll(webhook_endpoint, rolling_datetime)

      webhook_secret = CaptainHook.TestRepo.reload!(webhook_secret)

      assert new_webhook_secret.id != webhook_secret.id
      assert new_webhook_secret.secret != webhook_secret.secret
      assert new_webhook_secret.started_at != rolling_datetime

      assert_in_delta DateTime.to_unix(new_webhook_secret.started_at),
                      DateTime.to_unix(DateTime.utc_now()),
                      100

      assert new_webhook_secret.main?
      assert is_nil(new_webhook_secret.ended_at)

      assert webhook_secret.ended_at == rolling_datetime
      refute webhook_secret.main?
    end

    test "when rolling with a ended datetime that is more than 24 hours, return an error tuple with a invalid changeset" do
      webhook_endpoint = insert!(:webhook_endpoint)
      insert!(:webhook_secret, webhook_endpoint_id: webhook_endpoint.id)
      utc_now = utc_now()

      assert {:error, %Ecto.Changeset{} = changeset} =
               WebhookSecrets.roll(webhook_endpoint, utc_now |> DateTime.add(25 * 3600))

      refute changeset.valid?
      assert %{ended_at: ["must be in the next 24 hours"]} = errors_on(changeset)
    end
  end
end
