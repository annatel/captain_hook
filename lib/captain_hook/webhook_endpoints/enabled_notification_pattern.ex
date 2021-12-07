defmodule CaptainHook.WebhookEndpoints.EnabledNotificationPattern do
  use Ecto.Schema

  import Ecto.Changeset, only: [cast: 3, validate_required: 2, validate_format: 3]

  alias CaptainHook.WebhookEndpoints.WebhookEndpoint

  @type t :: %__MODULE__{
          id: integer,
          webhook_endpoint: WebhookEndpoint.t(),
          webhook_endpoint_id: binary,
          pattern: binary,
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  schema "captain_hook_webhook_endpoint_enabled_notification_patterns" do
    belongs_to(:webhook_endpoint, WebhookEndpoint, type: Shortcode.Ecto.UUID, prefix: "we")

    field(:pattern, :string)

    timestamps()
  end

  @doc false
  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = enabled_notification_pattern, attrs) when is_struct(attrs) do
    attrs = Map.from_struct(attrs)

    enabled_notification_pattern
    |> changeset(attrs)
  end

  def changeset(%__MODULE__{} = enabled_notification_pattern, attrs) when is_map(attrs) do
    enabled_notification_pattern
    |> cast(attrs, [:webhook_endpoint_id, :pattern])
    |> validate_required([:pattern])
    |> validate_format(
      :pattern,
      AntlUtilsElixir.Wildcard.pattern_regex!(
        CaptainHook.notification_pattern_separator()
      )
    )
  end
end
