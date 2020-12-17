defmodule CaptainHook.WebhookNotifications.WebhookNotification do
  use Ecto.Schema

  import Ecto.Changeset, only: [cast: 3, validate_required: 2]

  @primary_key {:id, Shortcode.Ecto.UUID, autogenerate: true, prefix: "wn"}
  @foreign_key_type :binary_id

  schema "captain_hook_webhook_notifications" do
    field(:created_at, :utc_datetime)
    field(:data, :map)
    field(:livemode, :boolean)
    field(:resource_id, :string)
    field(:resource_type, :string)
    field(:sequence, :integer)
    field(:type, :string)
    field(:webhook, :string)

    timestamps()
  end

  @spec changeset(WebhookNotification.t(), map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = webhook_notification, attrs) when is_map(attrs) do
    webhook_notification
    |> cast(attrs, [
      :created_at,
      :data,
      :livemode,
      :resource_id,
      :resource_type,
      :sequence,
      :type,
      :webhook
    ])
    |> validate_required([:created_at, :data, :livemode, :sequence, :type, :webhook])
  end
end
