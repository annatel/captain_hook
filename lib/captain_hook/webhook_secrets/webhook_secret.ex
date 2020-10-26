defmodule CaptainHook.WebhookSecrets.WebhookSecret do
  use Ecto.Schema
  import Ecto.Changeset, only: [cast: 3, validate_required: 2]

  alias AntlUtilsEcto.Changeset, as: AntlUtilsEctoChangeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "captain_hook_webhook_secrets" do
    field(:secret, :string)

    field(:started_at, :utc_datetime)
    field(:ended_at, :utc_datetime)

    timestamps()
  end

  @spec create_changeset(WebhookSecret.t(), map()) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = webhook_secret, attrs) when is_map(attrs) do
    webhook_secret
    |> cast(attrs, [:secret, :started_at])
    |> validate_required([:secret, :started_at])
  end

  @spec remove_changeset(WebhookSecret.t(), map()) :: Ecto.Changeset.t()
  def remove_changeset(%__MODULE__{} = webhook_secret, attrs) when is_map(attrs) do
    webhook_secret
    |> cast(attrs, [:ended_at])
    |> validate_required([:ended_at])
    |> AntlUtilsEctoChangeset.validate_datetime_gte(:ended_at, :started_at)
  end
end
