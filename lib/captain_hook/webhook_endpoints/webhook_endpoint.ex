defmodule CaptainHook.WebhookEndpoints.WebhookEndpoint do
  use Ecto.Schema

  import Ecto.Changeset, only: [cast: 3, cast_assoc: 2, put_change: 3, validate_required: 2]

  alias CaptainHook.WebhookEndpoints.EnabledNotificationType

  @type t :: %__MODULE__{
          enabled_notification_types: [EnabledNotificationType.t()],
          ended_at: DateTime.t() | nil,
          headers: map | nil,
          id: binary,
          inserted_at: DateTime.t(),
          is_enabled: boolean,
          is_insecure_allowed: boolean,
          livemode: boolean,
          secret: binary | nil,
          started_at: DateTime.t(),
          updated_at: DateTime.t(),
          topic: binary,
          url: binary
        }

  @primary_key {:id, Shortcode.Ecto.UUID, autogenerate: true, prefix: "we"}
  @foreign_key_type :binary_id
  schema "captain_hook_webhook_endpoints" do
    field(:started_at, :utc_datetime)
    field(:ended_at, :utc_datetime)

    has_many(:enabled_notification_types, EnabledNotificationType, on_replace: :delete)
    field(:headers, :map)
    field(:is_enabled, :boolean, default: true)
    field(:is_insecure_allowed, :boolean, default: false)
    field(:livemode, :boolean)
    field(:secret, :string, virtual: true)
    field(:topic, :string)
    field(:url, :string)

    timestamps()
  end

  @doc false
  @spec create_changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = webhook_endpoint, attrs) when is_map(attrs) do
    webhook_endpoint
    |> cast(attrs, [
      :started_at,
      :headers,
      :is_insecure_allowed,
      :livemode,
      :secret,
      :topic,
      :url
    ])
    |> put_change_started_at_now()
    |> validate_required([:livemode, :topic, :url])
    |> cast_assoc(:enabled_notification_types)
  end

  @doc false
  @spec update_changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def update_changeset(%__MODULE__{} = webhook_endpoint, attrs) when is_map(attrs) do
    webhook_endpoint
    |> cast(attrs, [:headers, :is_enabled, :is_insecure_allowed, :url])
    |> cast_assoc(:enabled_notification_types)
  end

  @doc false
  @spec remove_changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def remove_changeset(%__MODULE__{} = webhook_endpoint, attrs) when is_map(attrs) do
    webhook_endpoint
    |> cast(attrs, [:ended_at])
    |> validate_required([:ended_at])
    |> AntlUtilsEcto.Changeset.validate_datetime_gte(:ended_at, :started_at)
    |> put_change(:is_enabled, false)
  end

  defp put_change_started_at_now(%Ecto.Changeset{} = changeset) do
    changeset
    |> put_change(:started_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end
end
