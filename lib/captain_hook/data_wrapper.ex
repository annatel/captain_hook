defmodule CaptainHook.DataWrapper do
  @enforce_keys [
    :webhook_endpoint_id,
    :event_type,
    :event_id,
    :resource_type,
    :resource_id,
    :data
  ]
  @derive {Jason.Encoder, except: [:__struct__]}
  defstruct [
    :webhook_endpoint_id,
    :event_type,
    :resource_type,
    :resource_id,
    :request_id,
    :data,
    webhook_result_handler: nil
  ]

  @type t :: %__MODULE__{
          webhook_endpoint_id: binary(),
          event_type: binary(),
          resource_type: binary(),
          resource_id: binary() | integer(),
          webhook_result_handler: atom() | binary(),
          data: map()
        }

  def new(webhook_endpoint_id, event_type, resource_type, resource_id, data, opts) do
    fields = [
      webhook_endpoint_id: webhook_endpoint_id,
      event_type: event_type,
      event_id: Ecto.UUID.generate(),
      resource_type: resource_type |> to_string(),
      resource_id: resource_id |> to_string(),
      data: data,
      webhook_result_handler: Keyword.get(opts, :webhook_result_handler)
    ]

    struct!(__MODULE__, fields)
  end
end
