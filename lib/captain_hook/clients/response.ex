defmodule CaptainHook.Clients.Response do
  defstruct requested_at: nil,
            request_url: nil,
            request_body: nil,
            status_code: nil,
            response_body: nil,
            client_error_message: nil
end
