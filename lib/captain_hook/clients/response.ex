defmodule CaptainHook.Clients.Response do
  defstruct client_error_message: nil,
            request_body: nil,
            request_headers: nil,
            request_url: nil,
            requested_at: nil,
            status: nil,
            response_body: nil

  @type t :: %__MODULE__{
          client_error_message: binary,
          request_body: binary,
          request_headers: map,
          request_url: binary,
          requested_at: DateTime.t(),
          status: binary
        }
end
