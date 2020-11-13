defmodule CaptainHook.WebhookEndpoints.WebhookEndpoint do
  use Ecto.Schema
  import Ecto.Changeset, only: [cast: 3, validate_required: 2]

  alias AntlUtilsEcto.Changeset, as: AntlUtilsEctoChangeset

  @primary_key {:id, Shortcode.Ecto.UUID, autogenerate: true, prefix: "we"}
  @foreign_key_type :binary_id

  schema "captain_hook_webhook_endpoints" do
    field(:webhook, :string)

    field(:started_at, :utc_datetime)
    field(:ended_at, :utc_datetime)

    field(:livemode, :boolean)

    field(:allow_insecure, :boolean, default: false)
    field(:headers, :map)
    field(:metadata, :map)
    field(:url, :string)
    field(:secret, :string, virtual: true)

    timestamps()
  end

  @spec create_changeset(WebhookEndpoint.t(), map()) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = webhook_endpoint, attrs) when is_map(attrs) do
    webhook_endpoint
    |> cast(attrs, [:webhook, :started_at, :livemode, :url, :metadata, :headers, :allow_insecure])
    |> validate_required([:webhook, :livemode, :started_at, :url])
  end

  @spec update_changeset(WebhookEndpoint.t(), map()) :: Ecto.Changeset.t()
  def update_changeset(%__MODULE__{} = webhook_endpoint, attrs) when is_map(attrs) do
    webhook_endpoint
    |> cast(attrs, [:url, :metadata, :headers, :allow_insecure])
  end

  @spec remove_changeset(WebhookEndpoint.t(), map()) :: Ecto.Changeset.t()
  def remove_changeset(%__MODULE__{} = webhook_endpoint, attrs) when is_map(attrs) do
    webhook_endpoint
    |> cast(attrs, [:ended_at])
    |> validate_required([:ended_at])
    |> AntlUtilsEctoChangeset.validate_datetime_gte(:ended_at, :started_at)
  end
end
