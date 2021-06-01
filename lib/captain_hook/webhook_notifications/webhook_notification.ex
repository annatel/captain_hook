defmodule CaptainHook.WebhookNotifications.WebhookNotification do
  use Ecto.Schema

  import Ecto.Changeset, only: [assoc_constraint: 2, cast: 3, validate_required: 2]

  alias CaptainHook.WebhookEndpoints.WebhookEndpoint

  @type t :: %__MODULE__{
          attempt: integer,
          created_at: DateTime.t(),
          data: map,
          id: binary,
          idempotency_key: binary,
          inserted_at: DateTime.t(),
          next_retry_at: DateTime.t() | nil,
          resource_id: binary | nil,
          resource_object: binary | nil,
          sequence: integer,
          succeeded_at: DateTime.t() | nil,
          type: binary,
          webhook_endpoint_id: binary
        }

  @primary_key {:id, Shortcode.Ecto.UUID, autogenerate: true, prefix: "wn"}
  @foreign_key_type :binary_id
  schema "captain_hook_webhook_notifications" do
    belongs_to(:webhook_endpoint, WebhookEndpoint, type: Shortcode.Ecto.UUID, prefix: "we")

    field(:attempt, :integer, default: 0)
    field(:created_at, :utc_datetime)
    field(:data, :map)
    field(:idempotency_key, :string)
    field(:next_retry_at, :utc_datetime)
    field(:resource_id, :string)
    field(:resource_object, :string)
    field(:sequence, :integer)
    field(:succeeded_at, :utc_datetime)
    field(:type, :string)

    timestamps()
  end

  @doc false
  @spec create_changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = webhook_notification, attrs) when is_map(attrs) do
    webhook_notification
    |> cast(attrs, [
      :created_at,
      :data,
      :resource_id,
      :resource_object,
      :sequence,
      :type,
      :webhook_endpoint_id
    ])
    |> validate_required([:created_at, :data, :sequence, :type, :webhook_endpoint_id])
    |> assoc_constraint(:webhook_endpoint)
  end

  @spec update_changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def update_changeset(%__MODULE__{} = webhook_notification, attrs) when is_map(attrs) do
    webhook_notification
    |> cast(attrs, [:attempt, :next_retry_at, :succeeded_at])
    |> validate_required([:attempt])
  end
end
