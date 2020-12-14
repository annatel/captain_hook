defmodule CaptainHook.WebhookEndpoints.EnabledNotificationType do
  use Ecto.Schema

  import Ecto.Changeset, only: [cast: 3, validate_required: 2]

  alias CaptainHook.WebhookEndpoints.WebhookEndpoint

  schema "captain_hook_webhook_endpoint_enabled_notification_types" do
    belongs_to(:webhook_endpoint, WebhookEndpoint, type: Shortcode.Ecto.UUID, prefix: "we")

    field(:name, :string)

    timestamps()
  end

  @spec changeset(EnabledNotificationType.t(), map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = enabled_notification_type, attrs) when is_struct(attrs) do
    attrs = Map.from_struct(attrs)

    enabled_notification_type
    |> changeset(attrs)
  end

  def changeset(%__MODULE__{} = enabled_notification_type, attrs) when is_map(attrs) do
    enabled_notification_type
    |> cast(attrs, [:webhook_endpoint_id, :name])
    |> validate_required([:name])
  end
end
