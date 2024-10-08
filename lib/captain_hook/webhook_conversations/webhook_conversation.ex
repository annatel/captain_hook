defmodule CaptainHook.WebhookConversations.WebhookConversation do
  use Ecto.Schema

  import Ecto.Changeset,
    only: [assoc_constraint: 2, cast: 3, validate_inclusion: 3, validate_required: 2]

  alias CaptainHook.WebhookNotifications.WebhookNotification

  @type t :: %__MODULE__{
          client_error_message: binary,
          http_status: integer,
          id: binary,
          inserted_at: DateTime.t(),
          object: binary,
          request_body: binary,
          request_headers: map,
          request_url: binary,
          requested_at: DateTime.t(),
          response_body: binary,
          responded_at: DateTime.t(),
          sequence: integer,
          status: binary,
          webhook_notification_id: binary,
          webhook_notification: WebhookNotification.t()
        }

  @primary_key {:id, Shortcode.Ecto.UUID, autogenerate: true, prefix: "wc"}
  @foreign_key_type :binary_id
  @derive {Jason.Encoder, except: [:__meta__, :webhook_notification]}
  schema "captain_hook_webhook_conversations" do
    belongs_to(:webhook_notification, WebhookNotification,
      type: Shortcode.Ecto.UUID,
      prefix: "wn"
    )

    field(:client_error_message, :string)
    field(:http_status, :integer)
    field(:request_body, :string)
    field(:request_headers, :map)
    field(:request_url, :string)
    field(:requested_at, :utc_datetime)
    field(:response_body, :string)
    field(:responded_at, :utc_datetime)
    field(:sequence, :integer)
    field(:status, :string)

    timestamps(updated_at: false)
    field(:object, :string, default: "webhook_conversation")
  end

  @doc false
  @spec new!(map) :: WebhookConversation.t()
  def new!(fields \\ %{})
  def new!(fields) when is_struct(fields), do: fields |> Map.from_struct() |> new!()

  def new!(fields) when is_map(fields) do
    %__MODULE__{}
    |> changeset(fields)
    |> Ecto.Changeset.apply_action!(:insert)
  end

  @doc false
  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = webhook_conversation, attrs) when is_map(attrs) do
    webhook_conversation
    |> cast(attrs, [
      :webhook_notification_id,
      :client_error_message,
      :http_status,
      :request_body,
      :request_headers,
      :request_url,
      :requested_at,
      :response_body,
      :responded_at,
      :sequence,
      :status
    ])
    |> validate_required([
      :webhook_notification_id,
      :request_body,
      :request_url,
      :requested_at,
      :sequence,
      :status
    ])
    |> validate_inclusion(:status, Map.values(statuses()))
    |> assoc_constraint(:webhook_notification)
  end

  @spec statuses :: %{failed: binary(), succeeded: binary()}
  def statuses do
    %{
      failed: "failed",
      succeeded: "succeeded"
    }
  end
end
