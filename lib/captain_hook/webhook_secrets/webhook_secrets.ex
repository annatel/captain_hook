defmodule CaptainHook.WebhookSecrets do
  import Ecto.Changeset, only: [add_error: 3, fetch_field!: 2]

  alias Ecto.Multi
  alias AntlUtilsElixir.DateTime.Period

  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookSecrets.{WebhookSecret, WebhookSecretQueryable}

  @secret_length 32
  @secret_prefix "whsec"
  @one_day_in_seconds 24 * 3600
  @buffer_time_in_seconds 100

  @spec list_webhook_secrets(WebhookEndpoint.t()) :: [WebhookSecret.t()]
  def list_webhook_secrets(
        %WebhookEndpoint{} = webhook_endpoint,
        period_status \\ :ongoing,
        period_status_at \\ DateTime.utc_now()
      ) do
    WebhookSecretQueryable.queryable()
    |> WebhookSecretQueryable.filter(webhook_endpoint_id: webhook_endpoint.id)
    |> WebhookSecretQueryable.filter_by_status(period_status, period_status_at)
    |> CaptainHook.repo().all()
  end

  @spec create_webhook_secret(WebhookEndpoint.t(), DateTime.t()) ::
          {:ok, WebhookSecret.t()} | {:error, Ecto.Changeset.t()}
  def create_webhook_secret(%WebhookEndpoint{} = webhook_endpoint, %DateTime{} = started_at) do
    attrs = %{webhook_endpoint_id: webhook_endpoint.id, started_at: started_at, main?: true}

    %WebhookSecret{}
    |> WebhookSecret.create_changeset(attrs)
    |> validate_create_changes()
    |> CaptainHook.repo().insert()
  end

  def remove_webhook_secret(%WebhookSecret{} = webhook_secret, %DateTime{} = ended_at) do
    webhook_secret
    |> WebhookSecret.remove_changeset(%{main?: false, ended_at: expires_at})
    |> validate_remove_changes()
    |> CaptainHook.repo().update()
  end

  @spec roll(WebhookEndpoint.t(), DateTime.t()) ::
          {:ok, WebhookSecret.t()} | {:error, Ecto.Changeset.t()}
  def roll(
        %WebhookEndpoint{} = webhook_endpoint,
        %DateTime{} = expires_at \\ DateTime.utc_now()
      ) do
    [main_webhook_secret] =
      webhook_endpoint
      |> list_webhook_secrets()
      |> Enum.filter(& &1.main?)

    Multi.new()
    |> Multi.run(:remove_current_main_webhook_secret, fn _, %{} ->
      remove_webhook_secret(main_webhook_secret, expires_at)
    end)
    |> Multi.run(:create_webhook_secret, fn _, %{} ->
      create_webhook_secret(webhook_endpoint, DateTime.utc_now())
    end)
    |> CaptainHook.repo().transaction()
    |> case do
      {:ok, %{create_webhook_secret: %WebhookSecret{} = webhook_secret}} -> {:ok, webhook_secret}
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  @spec generate_secret() :: binary
  def generate_secret() do
    prefix_separator = "_"

    replacement =
      [?0..?9, ?a..?z, ?A..?Z]
      |> Enum.flat_map(&Enum.to_list/1)
      |> Enum.random()
      |> List.wrap()
      |> to_string()

    secret =
      :crypto.strong_rand_bytes(@secret_length)
      |> Base.url_encode64(padding: false)
      |> String.replace(prefix_separator, replacement)
      |> binary_part(0, @secret_length)

    "#{@secret_prefix}#{prefix_separator}#{secret}"
  end

  defp has_main_secret_ongoing?(webhook_endpoint_id, %DateTime{} = datetime)
       when is_binary(webhook_endpoint_id) do
    WebhookSecretQueryable.queryable()
    |> WebhookSecretQueryable.filter(webhook_endpoint_id: webhook_endpoint_id, main?: true)
    |> WebhookSecretQueryable.filter_by_status(:ongoing, DateTime.utc_now())
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

  defp validate_remove_changes(%Ecto.Changeset{valid?: false} = changeset), do: changeset

  defp validate_remove_changes(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_not_ends_after_the_next_day()
  end

  defp validate_uniq_main_webhook_secret(%Ecto.Changeset{} = changeset) do
    webhook_endpoint_id = fetch_field!(changeset, :webhook_endpoint_id)
    started_at = fetch_field!(changeset, :started_at)

    if has_main_secret_ongoing?(webhook_endpoint_id, started_at) do
      changeset |> add_error(:main?, "already exists")
    else
      changeset
    end
  end

  defp validate_not_ends_after_the_next_day(%Ecto.Changeset{} = changeset) do
    ended_at = fetch_field!(changeset, :ended_at)
    utc_now = DateTime.utc_now()

    if DateTime.diff(ended_at, utc_now) > @one_day_in_seconds + @buffer_time_in_seconds do
      changeset |> add_error(:ended_at, "must be in the next 24 hours")
    else
      changeset
    end
  end
end
