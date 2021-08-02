defmodule CaptainHook.Clients.Response do
  @moduledoc false

  defstruct client_error_message: nil,
            request_body: nil,
            request_headers: nil,
            request_method: nil,
            request_url: nil,
            requested_at: nil,
            response_body: nil,
            response_http_status: nil,
            responded_at: nil,
            success?: nil

  @type t :: %__MODULE__{
          client_error_message: binary | nil,
          request_body: binary | nil,
          request_headers: map | nil,
          request_method: binary | nil,
          request_url: binary | nil,
          requested_at: DateTime.t() | nil,
          response_body: binary | nil,
          response_http_status: binary | nil,
          responded_at: binary | nil,
          success?: boolean | nil
        }
end
