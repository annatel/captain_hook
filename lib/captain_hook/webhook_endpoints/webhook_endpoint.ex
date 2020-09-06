defmodule CaptainHook.WebhookEndpoints.WebhookEndpoint do
  use Ecto.Schema
  import Ecto.Changeset, only: [cast: 3, validate_required: 2]

  alias AntlDateTimeUtils.Ecto.Changeset, as: AntlDateTimeUtilsEctoChangeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "captain_hook_webhook_endpoints" do
    field(:webhook, :string)

    field(:started_at, :utc_datetime)
    field(:ended_at, :utc_datetime)

    field(:url, :string)
    field(:metadata, :map)
    field(:headers, :map)

    timestamps()
  end

  @spec create_changeset(WebhookEndpoint.t(), map()) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = webhook_endpoint, attrs) when is_map(attrs) do
    webhook_endpoint
    |> cast(attrs, [:webhook, :started_at, :url, :metadata, :headers])
    |> validate_required([:webhook, :started_at, :url])
  end

  @spec update_changeset(WebhookEndpoint.t(), map()) :: Ecto.Changeset.t()
  def update_changeset(%__MODULE__{} = webhook_endpoint, attrs) when is_map(attrs) do
    webhook_endpoint
    |> cast(attrs, [:metadata, :headers])
  end

  @spec remove_changeset(WebhookEndpoint.t(), map()) :: Ecto.Changeset.t()
  def remove_changeset(%__MODULE__{} = webhook_endpoint, attrs) when is_map(attrs) do
    webhook_endpoint
    |> cast(attrs, [:ended_at])
    |> validate_required([:ended_at])
    |> AntlDateTimeUtilsEctoChangeset.validate_datetime_gte(:ended_at, :started_at)
  end
end
