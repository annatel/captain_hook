defmodule CaptainHook.Clients.Response do
  defstruct request_url: nil,
            request_headers: nil,
            request_body: nil,
            requested_at: nil,
            status: nil,
            response_body: nil,
            client_error_message: nil
end
