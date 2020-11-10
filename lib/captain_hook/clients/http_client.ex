defmodule CaptainHook.Clients.HttpClient do
  require Logger

  alias CaptainHook.Clients.Response

  @pool_timeout 5_000
  @receive_timeout 15_000

  @spec call(binary, map(), map(), keyword) :: Response.t()
  def call(url, body, headers, opts \\ [])
      when is_binary(url) and is_map(body) and is_map(headers) do
    secrets = Keyword.get(opts, :secrets)
    _allow_insecure = Keyword.get(opts, :allow_insecure)

    encoded_body = Jason.encode!(body)

    now = DateTime.utc_now()

    headers =
      headers
      |> Recase.Enumerable.convert_keys(&Recase.to_header/1)
      |> Map.put("Content-Type", "application/json")
      |> Map.put("User-Agent", "CaptainHook/1.0; +(https://github.com/annatel/captain_hook)")

    headers =
      if secrets,
        do:
          headers
          |> Map.put("Signature", build_signature(encoded_body, DateTime.to_unix(now), secrets)),
        else: headers

    # request_options =
    #   if Keyword.get(options, :allow_insecure),
    #     do: [{:hackney, [:insecure]} | request_options],
    #     else: request_options

    response =
      Finch.build(:post, url, Map.to_list(headers), encoded_body)
      |> Finch.request(CaptainHookFinch,
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

  defp process_http_call_response(
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

  defp process_http_call_response(
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

  def build_signature(body, timestamp, secrets) when is_binary(body) and length(secrets) > 0 do
    signature = "t=#{timestamp},"

    secrets
    |> Enum.reduce(signature, fn secret, acc ->
      acc <> "v1=#{signature(body, timestamp, secret)},"
    end)
    |> String.trim(",")
  end

  defp signature(body, timestamp, secret) do
    signed_payload = "#{timestamp}.#{body}"

    :crypto.mac(:hmac, :sha256, secret, signed_payload)
    |> Base.encode16(case: :lower)
  end
end
