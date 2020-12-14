defmodule CaptainHook.WebhookNotifications.WebhookNotification do
  use Ecto.Schema

  import Ecto.Changeset,
    only: [assoc_constraint: 2, cast: 3, validate_inclusion: 3, validate_required: 2]

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
    |> validate_inclusion(:status, Map.values(status()))
    |> assoc_constraint(:webhook_endpoint)
  end

  @spec status :: %{failed: binary(), success: binary()}
  def status do
    %{
      success: "success",
      failed: "failed"
    }
  end
end
