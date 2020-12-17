defmodule CaptainHook.WebhookConversations.WebhookConversation do
  use Ecto.Schema

  import Ecto.Changeset,
    only: [assoc_constraint: 2, cast: 3, validate_inclusion: 3, validate_required: 2]

  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookNotifications.WebhookNotification

  @primary_key {:id, Shortcode.Ecto.UUID, autogenerate: true, prefix: "wc"}
  @foreign_key_type :binary_id

  schema "captain_hook_webhook_conversations" do
    belongs_to(:webhook_endpoint, WebhookEndpoint, type: Shortcode.Ecto.UUID, prefix: "we")

    belongs_to(:webhook_notification, WebhookNotification, type: Shortcode.Ecto.UUID, prefix: "wn")

    field(:sequence, :integer)
    field(:requested_at, :utc_datetime)
    field(:request_url, :string)
    field(:request_headers, :map)
    field(:request_body, :string)

    field(:http_status, :integer)
    field(:response_body, :string)
    field(:client_error_message, :string)

    field(:status, :string)

    timestamps()
  end

  @spec changeset(WebhookConversation.t(), map()) :: Ecto.Changeset.t()
  def changeset(%__MODULE__{} = webhook_conversation, attrs) when is_map(attrs) do
    webhook_conversation
    |> cast(attrs, [
      :webhook_endpoint_id,
      :webhook_notification_id,
      :sequence,
      :requested_at,
      :request_url,
      :request_headers,
      :request_body,
      :http_status,
      :response_body,
      :client_error_message,
      :status
    ])
    |> validate_required([
      :webhook_endpoint_id,
      :webhook_notification_id,
      :sequence,
      :requested_at,
      :request_url,
      :request_body,
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
