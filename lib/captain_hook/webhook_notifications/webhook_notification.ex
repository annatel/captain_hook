defmodule CaptainHook.WebhookNotifications.WebhookNotification do
  use Ecto.Schema

  import Ecto.Changeset, only: [assoc_constraint: 2, cast: 3, validate_required: 2]

  alias CaptainHook.WebhookEndpoints.WebhookEndpoint

  @type t :: %__MODULE__{
          created_at: DateTime.t(),
          data: map,
          id: binary,
          inserted_at: DateTime.t(),
          resource_id: binary | nil,
          resource_type: binary | nil,
          sequence: integer,
          type: binary,
          webhook_endpoint_id: binary
        }

  @primary_key {:id, Shortcode.Ecto.UUID, autogenerate: true, prefix: "wn"}
  @foreign_key_type :binary_id
  schema "captain_hook_webhook_notifications" do
    belongs_to(:webhook_endpoint, WebhookEndpoint, type: Shortcode.Ecto.UUID, prefix: "we")

    field(:created_at, :utc_datetime)
    field(:data, :map)
    field(:idempotency_key, :string)
    field(:resource_id, :string)
    field(:resource_type, :string)
    field(:sequence, :integer)
    field(:succeeded_at, :utc_datetime)
    field(:type, :string)

    timestamps()
  end

  @doc false
  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = webhook_notification, attrs) when is_map(attrs) do
    webhook_notification
    |> cast(attrs, [
      :created_at,
      :data,
      :resource_id,
      :resource_type,
      :sequence,
      :type,
      :webhook_endpoint_id
    ])
    |> validate_required([:created_at, :data, :sequence, :type, :webhook_endpoint_id])
    |> assoc_constraint(:webhook_endpoint)
  end
end
