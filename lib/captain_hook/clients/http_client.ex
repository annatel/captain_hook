defmodule CaptainHook.Clients.HttpClient do
  @moduledoc false

  require Logger

  alias CaptainHook.Clients.Response

  @content_type "application/json"
  @user_agent "CaptainHook/1.0; +(https://github.com/annatel/captain_hook)"

  @pool_timeout 5_000
  @receive_timeout 15_000

  @spec call(binary, map(), map(), keyword) :: Response.t()
  def call(url, body, headers, opts \\ [])
      when is_binary(url) and is_map(body) and is_map(headers) do
    secrets = Keyword.get(opts, :secrets)
    is_insecure_allowed = Keyword.get(opts, :is_insecure_allowed)

    headers =
      headers
      |> Recase.Enumerable.convert_keys(&Recase.to_kebab/1)
      |> Map.put("content-type", @content_type)
      |> Map.put_new("user-agent", @user_agent)

    request =
      %{
        request_body: Jason.encode!(body),
        request_headers: headers,
        request_method: "POST",
        request_url: url,
        requested_at: DateTime.utc_now()
      }
      |> maybe_add_signature_header(secrets)

    response = send_request(request, is_insecure_allowed: is_insecure_allowed)

    Response
    |> struct!(Map.merge(request, response))
  end

  defp send_request(request, opts) do
    request
    |> tap(&Logger.debug("CaptainHook request:, #{inspect(&1)}"))
    |> do_send_request(opts)
    |> tap(&Logger.debug("CaptainHook response, #{inspect(&1)}"))
  end

  defp do_send_request(request, is_insecure_allowed: is_insecure_allowed) do
    finch_instance_name =
      unless is_insecure_allowed, do: CaptainHookFinch, else: CaptainHookFinchInsecure

    Finch.build(
      :post,
      request.request_url,
      Map.to_list(request.request_headers),
      request.request_body
    )
    |> Finch.request(finch_instance_name,
      pool_timeout: @pool_timeout,
      receive_timeout: @receive_timeout
    )
    |> case do
      {:ok, %Finch.Response{body: response_body, status: status}} ->
        %{
          response_body: response_body,
          response_http_status: status,
          responded_at: DateTime.utc_now(),
          success?: status in 200..299
        }

      {:error, error} ->
        %{client_error_message: Exception.message(error), success?: false}
    end
  end

  defp maybe_add_signature_header(request, nil), do: request

  defp maybe_add_signature_header(request, secrets) do
    headers =
      request.request_headers
      |> Map.put(
        "signature",
        CaptainHookSignature.sign(
          request.request_body,
          DateTime.to_unix(request.requested_at),
          secrets
        )
      )

    %{request | request_headers: headers}
  end
end
