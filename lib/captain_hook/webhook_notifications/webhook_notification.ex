defmodule CaptainHook.WebhookNotifications.WebhookNotification do
  use Ecto.Schema

  import Ecto.Changeset, only: [cast: 3, validate_required: 2]

  @primary_key {:id, Shortcode.Ecto.UUID, autogenerate: true, prefix: "not"}
  @foreign_key_type :binary_id

  schema "captain_hook_webhook_notifications" do
    field(:webhook, :string)

    field(:created_at, :utc_datetime)
    field(:data, :map)
    field(:resource_id, :string)
    field(:resource_type, :string)
    field(:sequence, :integer)
    field(:type, :string)

    timestamps()
  end

  @spec changeset(WebhookNotification.t(), map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = webhook_notification, attrs) when is_map(attrs) do
    webhook_notification
    |> cast(attrs, [:webhook, :created_at, :data, :resource_id, :resource_type, :sequence, :type])
    |> validate_required([:webhook, :created_at, :data, :sequence, :type])
  end
end
