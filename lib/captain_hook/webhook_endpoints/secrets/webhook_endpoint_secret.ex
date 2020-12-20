defmodule CaptainHook.WebhookEndpoints.Secrets.WebhookEndpointSecret do
  use Ecto.Schema
  import Ecto.Changeset, only: [assoc_constraint: 2, cast: 3, put_change: 3, validate_required: 2]

  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookEndpoints.Secrets

  schema "captain_hook_webhook_endpoint_secrets" do
    belongs_to(:webhook_endpoint, WebhookEndpoint, type: Shortcode.Ecto.UUID, prefix: "we")

    field(:started_at, :utc_datetime)
    field(:ended_at, :utc_datetime)

    field(:secret, :string)
    field(:is_main, :boolean)

    timestamps()
  end

  @spec create_changeset(WebhookEndpointSecret.t(), map()) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = webhook_secret, attrs) when is_map(attrs) do
    webhook_secret
    |> cast(attrs, [:webhook_endpoint_id, :started_at, :is_main])
    |> validate_required([:webhook_endpoint_id, :started_at, :is_main])
    |> put_change_secret()
    |> assoc_constraint(:webhook_endpoint)
  end

  @spec remove_changeset(WebhookEndpointSecret.t(), map()) :: Ecto.Changeset.t()
  def remove_changeset(%__MODULE__{} = webhook_secret, attrs) when is_map(attrs) do
    webhook_secret
    |> cast(attrs, [:ended_at, :is_main])
    |> validate_required([:ended_at, :is_main])
    |> AntlUtilsEcto.Changeset.validate_datetime_gte(:ended_at, :started_at)
  end

  defp put_change_secret(%Ecto.Changeset{} = changeset) do
    secret = Secrets.generate_secret()

    changeset
    |> put_change(:secret, secret)
  end
end
