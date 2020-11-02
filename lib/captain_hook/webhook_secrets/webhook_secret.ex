defmodule CaptainHook.WebhookSecrets.WebhookSecret do
  use Ecto.Schema
  import Ecto.Changeset, only: [assoc_constraint: 2, cast: 3, put_change: 3, validate_required: 2]

  alias AntlUtilsEcto.Changeset, as: AntlUtilsEctoChangeset

  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookSecrets

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "captain_hook_webhook_secrets" do
    belongs_to(:webhook_endpoint, WebhookEndpoint, type: Shortcode.Ecto.UUID, prefix: "we")

    field(:secret, :string)
    field(:main?, :boolean, source: :is_main)

    field(:started_at, :utc_datetime)
    field(:ended_at, :utc_datetime)

    timestamps()
  end

  @spec create_changeset(WebhookSecret.t(), map()) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = webhook_secret, attrs) when is_map(attrs) do
    webhook_secret
    |> cast(attrs, [:webhook_endpoint_id, :main?, :started_at])
    |> validate_required([:webhook_endpoint_id, :main?, :started_at])
    |> put_change_secret()
    |> assoc_constraint(:webhook_endpoint)
  end

  @spec remove_changeset(WebhookSecret.t(), map()) :: Ecto.Changeset.t()
  def remove_changeset(%__MODULE__{} = webhook_secret, attrs) when is_map(attrs) do
    webhook_secret
    |> cast(attrs, [:main?, :ended_at])
    |> validate_required([:main?, :ended_at])
    |> AntlUtilsEctoChangeset.validate_datetime_gte(:ended_at, :started_at)
  end

  defp put_change_secret(%Ecto.Changeset{} = changeset) do
    secret = WebhookSecrets.generate_secret()

    changeset
    |> put_change(:secret, secret)
  end
end
