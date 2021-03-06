defmodule CaptainHook.WebhookEndpoints.Secrets do
  @moduledoc false

  import Ecto.Changeset, only: [add_error: 3, fetch_field!: 2, prepare_changes: 2]

  alias Ecto.Multi

  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookEndpoints.Secrets.WebhookEndpointSecret

  @secret_length 32
  @secret_prefix "whsec"

  @spec list_webhook_endpoint_secrets(WebhookEndpoint.t()) :: [WebhookEndpointSecret.t()]
  def list_webhook_endpoint_secrets(%WebhookEndpoint{} = webhook_endpoint) do
    WebhookEndpointSecret
    |> AntlUtilsEcto.Query.where(:webhook_endpoint_id, webhook_endpoint.id)
    |> AntlUtilsEcto.Query.where_period_status(
      :ongoing,
      :started_at,
      :ended_at,
      DateTime.utc_now()
    )
    |> CaptainHook.repo().all()
  end

  @spec create_webhook_endpoint_secret(WebhookEndpoint.t(), DateTime.t()) ::
          {:ok, WebhookEndpointSecret.t()} | {:error, Ecto.Changeset.t()}
  def create_webhook_endpoint_secret(
        %WebhookEndpoint{} = webhook_endpoint,
        %DateTime{} = started_at
      ) do
    attrs = %{webhook_endpoint_id: webhook_endpoint.id, started_at: started_at, is_main: true}

    %WebhookEndpointSecret{}
    |> WebhookEndpointSecret.create_changeset(attrs)
    |> validate_create_changes()
    |> CaptainHook.repo().insert()
  end

  @spec remove_webhook_endpoint_secret(WebhookEndpointSecret.t(), DateTime.t()) ::
          {:ok, WebhookEndpointSecret.t()} | {:error, Ecto.Changeset.t()}
  def remove_webhook_endpoint_secret(
        %WebhookEndpointSecret{} = webhook_secret,
        %DateTime{} = ended_at
      ) do
    webhook_secret
    |> WebhookEndpointSecret.remove_changeset(%{is_main: false, ended_at: ended_at})
    |> CaptainHook.repo().update()
  end

  @spec roll_webhook_endpoint_secret(WebhookEndpoint.t(), DateTime.t()) ::
          {:ok, WebhookEndpointSecret.t()} | {:error, Ecto.Changeset.t()}
  def roll_webhook_endpoint_secret(
        %WebhookEndpoint{} = webhook_endpoint,
        %DateTime{} = expires_at \\ DateTime.utc_now()
      ) do
    [main_webhook_secret] =
      webhook_endpoint
      |> list_webhook_endpoint_secrets()
      |> Enum.filter(& &1.is_main)

    Multi.new()
    |> Multi.run(:remove_current_main_webhook_endpoint_secret, fn _, %{} ->
      remove_webhook_endpoint_secret(main_webhook_secret, expires_at)
    end)
    |> Multi.run(:create_webhook_endpoint_secret, fn _, %{} ->
      create_webhook_endpoint_secret(webhook_endpoint, DateTime.utc_now())
    end)
    |> CaptainHook.repo().transaction()
    |> case do
      {:ok, %{create_webhook_endpoint_secret: %WebhookEndpointSecret{} = webhook_secret}} ->
        {:ok, webhook_secret}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  @spec generate_secret() :: binary
  def generate_secret() do
    prefix_separator = "_"
    unfriendly_chars_to_copy_past = [prefix_separator, "-"]

    replacement =
      [?0..?9, ?a..?z, ?A..?Z]
      |> Enum.flat_map(&Enum.to_list/1)
      |> Enum.random()
      |> List.wrap()
      |> to_string()

    secret =
      :crypto.strong_rand_bytes(@secret_length)
      |> Base.url_encode64(padding: false)
      |> String.replace(unfriendly_chars_to_copy_past, replacement)
      |> binary_part(0, @secret_length)

    "#{@secret_prefix}#{prefix_separator}#{secret}"
  end

  defp has_main_webhook_endpoint_secret_ongoing?(webhook_endpoint_id, %DateTime{} = datetime)
       when is_binary(webhook_endpoint_id) do
    WebhookEndpointSecret
    |> AntlUtilsEcto.Query.where(:webhook_endpoint_id, webhook_endpoint_id)
    |> AntlUtilsEcto.Query.where(:is_main, true)
    |> AntlUtilsEcto.Query.where_period_status(:ongoing, :started_at, :ended_at, datetime)
    |> CaptainHook.repo().exists?()
  end

  defp validate_create_changes(%Ecto.Changeset{valid?: false} = changeset), do: changeset

  defp validate_create_changes(%Ecto.Changeset{} = changeset) do
    changeset
    |> prepare_changes(fn changeset ->
      changeset
      |> validate_uniq_main_webhook_secret()
    end)
  end

  defp validate_uniq_main_webhook_secret(%Ecto.Changeset{} = changeset) do
    webhook_endpoint_id = fetch_field!(changeset, :webhook_endpoint_id)
    started_at = fetch_field!(changeset, :started_at)

    if has_main_webhook_endpoint_secret_ongoing?(webhook_endpoint_id, started_at) do
      changeset |> add_error(:is_main, "already exists")
    else
      changeset
    end
  end
end
