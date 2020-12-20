defmodule CaptainHook.WebhookEndpoints.WebhookEndpoint do
  use Ecto.Schema

  import Ecto.Changeset, only: [cast: 3, cast_assoc: 2, validate_required: 2]

  alias CaptainHook.WebhookEndpoints.EnabledNotificationType

  @primary_key {:id, Shortcode.Ecto.UUID, autogenerate: true, prefix: "we"}
  @foreign_key_type :binary_id

  schema "captain_hook_webhook_endpoints" do
    field(:webhook, :string)

    field(:started_at, :utc_datetime)
    field(:ended_at, :utc_datetime)

    field(:livemode, :boolean)

    field(:allow_insecure, :boolean, default: false)
    has_many(:enabled_notification_types, EnabledNotificationType, on_replace: :delete)
    field(:headers, :map)
    field(:url, :string)
    field(:secret, :string, virtual: true)

    timestamps()
  end

  @spec create_changeset(WebhookEndpoint.t(), map()) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = webhook_endpoint, attrs) when is_map(attrs) do
    webhook_endpoint
    |> cast(attrs, [:webhook, :started_at, :livemode, :allow_insecure, :headers, :url])
    |> validate_required([:webhook, :livemode, :started_at, :url])
    |> cast_assoc(:enabled_notification_types)
  end

  @spec update_changeset(WebhookEndpoint.t(), map()) :: Ecto.Changeset.t()
  def update_changeset(%__MODULE__{} = webhook_endpoint, attrs) when is_map(attrs) do
    webhook_endpoint
    |> cast(attrs, [:allow_insecure, :headers, :url])
    |> cast_assoc(:enabled_notification_types)
  end

  @spec remove_changeset(WebhookEndpoint.t(), map()) :: Ecto.Changeset.t()
  def remove_changeset(%__MODULE__{} = webhook_endpoint, attrs) when is_map(attrs) do
    webhook_endpoint
    |> cast(attrs, [:ended_at])
    |> validate_required([:ended_at])
    |> AntlUtilsEcto.Changeset.validate_datetime_gte(:ended_at, :started_at)
  end
end
