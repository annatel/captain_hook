defmodule CaptainHook.Clients.Response do
  @moduledoc false

  defstruct client_error_message: nil,
            request_body: nil,
            request_headers: nil,
            request_url: nil,
            requested_at: nil,
            status: nil,
            response_body: nil

  @type t :: %__MODULE__{
          client_error_message: binary | nil,
          request_body: binary | nil,
          request_headers: map | nil,
          request_url: binary | nil,
          requested_at: DateTime.t() | nil,
          status: binary | nil,
          response_body: binary | nil
        }
end
