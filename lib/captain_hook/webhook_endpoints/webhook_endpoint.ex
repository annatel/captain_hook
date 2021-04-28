defmodule CaptainHook.WebhookEndpoints.WebhookEndpoint do
  use Ecto.Schema

  import Ecto.Changeset,
    only: [cast: 3, cast_assoc: 2, put_change: 3, validate_inclusion: 3, validate_required: 2]

  alias CaptainHook.WebhookEndpoints.EnabledNotificationType

  @type t :: %__MODULE__{
          id: binary,
          webhook: binary,
          started_at: DateTime.t(),
          ended_at: DateTime.t() | nil,
          livemode: boolean,
          allow_insecure: boolean,
          enabled_notification_types: [EnabledNotificationType.t()],
          headers: map | nil,
          url: binary,
          secret: binary | nil,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @primary_key {:id, Shortcode.Ecto.UUID, autogenerate: true, prefix: "we"}
  @foreign_key_type :binary_id
  schema "captain_hook_webhook_endpoints" do
    field(:allow_insecure, :boolean, default: false)
    field(:api_version, :string)
    has_many(:enabled_notification_types, EnabledNotificationType, on_replace: :delete)
    field(:ended_at, :utc_datetime)
    field(:headers, :map)
    field(:livemode, :boolean)
    field(:secret, :string, virtual: true)
    field(:started_at, :utc_datetime)
    field(:status, :string)
    field(:url, :string)
    field(:webhook, :string)

    timestamps()
  end

  @spec statuses :: %{disabled: binary, enabled: binary}
  def statuses, do: %{enabled: "enabled", disabled: "disabled"}

  @doc false
  @spec create_changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = webhook_endpoint, attrs) when is_map(attrs) do
    webhook_endpoint
    |> cast(attrs, [
      :allow_insecure,
      :api_version,
      :headers,
      :livemode,
      :started_at,
      :url,
      :webhook
    ])
    |> validate_required([:livemode, :started_at, :url, :webhook])
    |> cast_assoc(:enabled_notification_types)
    |> put_change(:status, statuses().enabled)
  end

  @doc false
  @spec update_changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def update_changeset(%__MODULE__{} = webhook_endpoint, attrs) when is_map(attrs) do
    webhook_endpoint
    |> cast(attrs, [:allow_insecure, :headers, :url, :status])
    |> cast_assoc(:enabled_notification_types)
    |> validate_inclusion(:status, Map.values(statuses()))
  end

  @doc false
  @spec remove_changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def remove_changeset(%__MODULE__{} = webhook_endpoint, attrs) when is_map(attrs) do
    webhook_endpoint
    |> cast(attrs, [:ended_at])
    |> validate_required([:ended_at])
    |> AntlUtilsEcto.Changeset.validate_datetime_gte(:ended_at, :started_at)
  end
end
