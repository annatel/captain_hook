defmodule CaptainHook.DataWrapper do
  @enforce_keys [
    :webhook_endpoint_id,
    :notification_type,
    :notification_id,
    :resource_type,
    :resource_id,
    :data
  ]
  @derive {Jason.Encoder, except: [:__struct__]}
  defstruct [
    :webhook_endpoint_id,
    :notification_type,
    :notification_id,
    :resource_type,
    :resource_id,
    :data,
    webhook_result_handler: nil
  ]

  @type t :: %__MODULE__{
          webhook_endpoint_id: binary(),
          notification_type: binary(),
          notification_id: binary(),
          resource_type: binary(),
          resource_id: binary() | integer(),
          data: map(),
          webhook_result_handler: atom() | binary()
        }

  def new(webhook_endpoint_id, notification_type, resource_type, resource_id, data, opts) do
    fields = [
      webhook_endpoint_id: webhook_endpoint_id,
      notification_type: notification_type,
      notification_id: Ecto.UUID.generate(),
      resource_type: resource_type |> to_string(),
      resource_id: resource_id |> to_string(),
      data: data,
      webhook_result_handler: Keyword.get(opts, :webhook_result_handler)
    ]

    struct!(__MODULE__, fields)
  end
end
