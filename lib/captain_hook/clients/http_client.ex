defmodule CaptainHook.Clients.HttpClient do
  require Logger

  alias CaptainHook.Clients.Response
  alias CaptainHook.Signature

  @pool_timeout 5_000
  @receive_timeout 15_000

  @spec call(binary, map(), map(), keyword) :: Response.t()
  def call(url, body, headers, opts \\ [])
      when is_binary(url) and is_map(body) and is_map(headers) do
    secrets = Keyword.get(opts, :secrets)
    allow_insecure = Keyword.get(opts, :allow_insecure)

    encoded_body = Jason.encode!(body)

    now = DateTime.utc_now()

    headers =
      headers
      |> Recase.Enumerable.convert_keys(&Recase.to_header/1)
      |> Map.put("Content-Type", "application/json")
      |> Map.put_new("User-Agent", "CaptainHook/1.0; +(https://github.com/annatel/captain_hook)")

    headers =
      if secrets,
        do:
          headers
          |> Map.put("Signature", Signature.sign(encoded_body, DateTime.to_unix(now), secrets)),
        else: headers

    finch_instance_name =
      unless allow_insecure, do: CaptainHookFinch, else: CaptainHookFinchInsecure

    response =
      Finch.build(:post, url, Map.to_list(headers), encoded_body)
      |> Finch.request(finch_instance_name,
        pool_timeout: @pool_timeout,
        receive_timeout: @receive_timeout
      )

    Logger.debug("#{inspect(response)}")

    response
    |> process_response(url, Enum.into(headers, %{}), encoded_body, now)
  end

  defp process_response(
         {:ok, %Finch.Response{status: status, body: response_body}},
         request_url,
         request_headers,
         encoded_request_body,
         %DateTime{} = requested_at
       )
       when status in 200..299 do
    %Response{
      request_url: request_url,
      request_headers: request_headers,
      request_body: encoded_request_body,
      requested_at: requested_at,
      status: status,
      response_body: response_body
    }
  end

  defp process_response(
         {:ok, %Finch.Response{status: status, body: response_body}},
         request_url,
         request_headers,
         encoded_request_body,
         %DateTime{} = requested_at
       ) do
    %Response{
      request_url: request_url,
      request_headers: request_headers,
      request_body: encoded_request_body,
      requested_at: requested_at,
      status: status,
      response_body: response_body
    }
  end

  defp process_response(
         {:error, error},
         url,
         request_headers,
         request_body,
         %DateTime{} = requested_at
       ) do
    %Response{
      request_url: url,
      request_headers: request_headers,
      request_body: request_body,
      requested_at: requested_at,
      client_error_message: Exception.message(error)
    }
  end
end
