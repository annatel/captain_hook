defmodule CaptainHook.WebhookConversations.WebhookConversation do
  use Ecto.Schema

  import Ecto.Changeset,
    only: [assoc_constraint: 2, cast: 3, validate_inclusion: 3, validate_required: 2]

  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookNotifications.WebhookNotification

  @type t :: %__MODULE__{
          client_error_message: binary,
          http_status: integer,
          id: binary,
          inserted_at: DateTime.t(),
          request_body: binary,
          request_headers: map,
          request_url: binary,
          requested_at: DateTime.t(),
          response_body: binary,
          sequence: integer,
          status: binary,
          webhook_endpoint_id: binary,
          webhook_endpoint: WebhookEndpoint.t() | nil,
          webhook_notification_id: binary,
          webhook_notification: WebhookNotification.t() | nil
        }

  @primary_key {:id, Shortcode.Ecto.UUID, autogenerate: true, prefix: "wc"}
  @foreign_key_type :binary_id
  schema "captain_hook_webhook_conversations" do
    belongs_to(:webhook_endpoint, WebhookEndpoint, type: Shortcode.Ecto.UUID, prefix: "we")

    belongs_to(:webhook_notification, WebhookNotification, type: Shortcode.Ecto.UUID, prefix: "wn")

    field(:client_error_message, :string)
    field(:http_status, :integer)
    field(:request_body, :string)
    field(:request_headers, :map)
    field(:request_url, :string)
    field(:requested_at, :utc_datetime)
    field(:response_body, :string)
    field(:sequence, :integer)
    field(:status, :string)

    timestamps(updated_at: false)
  end

  @doc false
  @spec changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = webhook_conversation, attrs) when is_map(attrs) do
    webhook_conversation
    |> cast(attrs, [
      :webhook_endpoint_id,
      :webhook_notification_id,
      :client_error_message,
      :http_status,
      :request_url,
      :request_headers,
      :request_body,
      :requested_at,
      :response_body,
      :sequence,
      :status,
      :wrap_data
    ])
    |> validate_required([
      :webhook_endpoint_id,
      :webhook_notification_id,
      :requested_at,
      :request_url,
      :request_body,
      :sequence,
      :status
    ])
    |> validate_inclusion(:status, Map.values(status()))
    |> assoc_constraint(:webhook_endpoint)
    |> assoc_constraint(:webhook_notification)
  end

  @spec status :: %{failed: binary(), success: binary()}
  def status do
    %{
      success: "success",
      failed: "failed"
    }
  end
end
