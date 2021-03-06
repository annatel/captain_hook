defmodule CaptainHook.WebhookEndpoints.Secrets.WebhookEndpointSecret do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset, only: [assoc_constraint: 2, cast: 3, put_change: 3, validate_required: 2]

  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookEndpoints.Secrets

  @one_day_in_seconds 24 * 3600
  @buffer_time_in_seconds 100
  @max_expiration_in_days 7

  @type t :: %__MODULE__{
          ended_at: DateTime.t() | nil,
          id: integer,
          is_main: boolean,
          secret: binary,
          started_at: DateTime.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t(),
          webhook_endpoint_id: binary
        }

  schema "captain_hook_webhook_endpoint_secrets" do
    belongs_to(:webhook_endpoint, WebhookEndpoint, type: Shortcode.Ecto.UUID, prefix: "we")

    field(:started_at, :utc_datetime)
    field(:ended_at, :utc_datetime)

    field(:is_main, :boolean)
    field(:secret, :string)

    timestamps()
  end

  @spec create_changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def create_changeset(%__MODULE__{} = webhook_secret, attrs) when is_map(attrs) do
    webhook_secret
    |> cast(attrs, [:is_main, :started_at, :webhook_endpoint_id])
    |> validate_required([:is_main, :started_at, :webhook_endpoint_id])
    |> put_change_secret()
    |> assoc_constraint(:webhook_endpoint)
  end

  @spec remove_changeset(%__MODULE__{}, map()) :: Ecto.Changeset.t()
  def remove_changeset(%__MODULE__{} = webhook_secret, attrs) when is_map(attrs) do
    max_expired_at =
      DateTime.utc_now()
      |> DateTime.add(
        @max_expiration_in_days * @one_day_in_seconds + @buffer_time_in_seconds,
        :second
      )
      |> DateTime.truncate(:second)

    webhook_secret
    |> cast(attrs, [:ended_at, :is_main])
    |> validate_required([:ended_at, :is_main])
    |> AntlUtilsEcto.Changeset.validate_datetime_gte(:ended_at, :started_at)
    |> AntlUtilsEcto.Changeset.validate_datetime_lte(:ended_at, max_expired_at)
  end

  defp put_change_secret(%Ecto.Changeset{} = changeset) do
    secret = Secrets.generate_secret()

    changeset
    |> put_change(:secret, secret)
  end
end
