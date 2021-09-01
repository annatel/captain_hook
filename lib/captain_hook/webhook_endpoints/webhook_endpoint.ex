defmodule CaptainHook.WebhookEndpoints.WebhookEndpoint do
  use CaptainHook.WebhookEndpoints.WebhookEndpointSchema

  import Ecto.Changeset, only: [cast: 3, cast_assoc: 3, put_change: 3, validate_required: 2]

  alias CaptainHook.WebhookEndpoints.EnabledNotificationPattern

  @type t :: %__MODULE__{
          api_version: binary | nil,
          created_at: DateTime.t(),
          deleted_at: DateTime.t() | nil,
          enabled_notification_patterns: [EnabledNotificationPattern.t()],
          headers: map | nil,
          id: binary,
          inserted_at: DateTime.t(),
          is_enabled: boolean,
          is_insecure_allowed: boolean,
          livemode: boolean,
          object: binary,
          secret: binary | nil,
          updated_at: DateTime.t(),
          url: binary
        }

  @primary_key {:id, Shortcode.Ecto.UUID, autogenerate: true, prefix: "we"}
  @foreign_key_type :binary_id
  schema "captain_hook_webhook_endpoints" do
    configurable_fields()

    field(:api_version, :string, default: "2021-01-01")
    field(:created_at, :utc_datetime)
    has_many(:enabled_notification_patterns, EnabledNotificationPattern, on_replace: :delete)
    field(:headers, :map)
    field(:is_enabled, :boolean, default: true)
    field(:is_insecure_allowed, :boolean, default: false)
    field(:livemode, :boolean)
    field(:secret, :string, virtual: true)
    field(:url, :string)

    field(:deleted_at, :utc_datetime)
    timestamps()
    field(:object, :string, default: "webhook_endpoint")
  end

  @doc false
  @spec create_changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = webhook_endpoint, attrs) when is_map(attrs) do
    webhook_endpoint
    |> cast(attrs, [
      :api_version,
      :headers,
      :is_insecure_allowed,
      :is_enabled,
      :livemode,
      :url
    ])
    |> put_change_created_at_now()
    |> validate_required([:livemode, :url])
    |> cast_assoc(:enabled_notification_patterns, required: true)
    |> validate_configurable_fields(attrs)
  end

  @doc false
  @spec update_changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def update_changeset(%__MODULE__{} = webhook_endpoint, attrs) when is_map(attrs) do
    webhook_endpoint
    |> cast(attrs, [:headers, :is_enabled, :is_insecure_allowed, :url])
    |> cast_assoc(:enabled_notification_patterns, required: true)
  end

  @doc false
  @spec remove_changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def remove_changeset(%__MODULE__{} = webhook_endpoint, attrs) when is_map(attrs) do
    webhook_endpoint
    |> cast(attrs, [:deleted_at])
    |> validate_required([:deleted_at])
    |> AntlUtilsEcto.Changeset.validate_datetime_gte(:deleted_at, :created_at)
    |> put_change(:is_enabled, false)
  end

  defp put_change_created_at_now(%Ecto.Changeset{} = changeset) do
    changeset
    |> put_change(:created_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end
end
