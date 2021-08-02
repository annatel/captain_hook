defmodule CaptainHook.WebhookEndpoints.EnabledNotificationType do
  use Ecto.Schema

  import Ecto.Changeset, only: [cast: 3, validate_required: 2, validate_format: 3]

  alias CaptainHook.WebhookEndpoints.WebhookEndpoint

  @type t :: %__MODULE__{
          id: integer,
          webhook_endpoint: WebhookEndpoint.t(),
          webhook_endpoint_id: binary,
          name: binary,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "captain_hook_webhook_endpoint_enabled_notification_types" do
    belongs_to(:webhook_endpoint, WebhookEndpoint, type: Shortcode.Ecto.UUID, prefix: "we")

    field(:name, :string)

    timestamps()
  end

  @doc false
  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = enabled_notification_type, attrs) when is_struct(attrs) do
    attrs = Map.from_struct(attrs)

    enabled_notification_type
    |> changeset(attrs)
  end

  def changeset(%__MODULE__{} = enabled_notification_type, attrs) when is_map(attrs) do
    enabled_notification_type
    |> cast(attrs, [:webhook_endpoint_id, :name])
    |> validate_required([:name])
    |> validate_format(
      :name,
      AntlUtilsElixir.Wildcard.pattern_regex!(
        CaptainHook.notification_type_separator(),
        CaptainHook.notification_type_wildcard()
      )
    )
  end
end
