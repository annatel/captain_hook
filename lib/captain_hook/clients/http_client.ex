defmodule CaptainHook.Clients.HttpClient do
  @behaviour CaptainHook.Clients.Behaviour

  # @http_adapter Application.get_env(:captain_hook, :http_adapter, HTTPoison)

  @timeout 2_000
  @rcv_timeout 5_000

  require Logger

  alias CaptainHook.Clients.Response

  @impl true
  @spec call(binary, map(), map(), keyword) :: Response.t()
  def call(url, body, headers, options \\ [])
      when is_binary(url) and is_map(body) and is_map(headers) do
    # encoded_body = Jason.encode!(body)

    # Logger.debug("#{inspect(url)} #{inspect(encoded_body)}")

    # headers =
    #   headers
    #   |> Recase.Enumerable.convert_keys(&Recase.to_header/1)
    #   |> Map.put("Content-Type", "application/json")
    #   |> Map.put("User-Agent", "CaptainHook/1.0; +(https://github.com/annatel/captain_hook)")
    #   |> Map.to_list()

    # request_options = [timeout: @timeout, recv_timeout: @rcv_timeout]

    # request_options =
    #   if Keyword.get(options, :allow_insecure),
    #     do: [{:hackney, [:insecure]} | request_options],
    #     else: request_options

    # http_result = @http_adapter.post(url, encoded_body, headers, request_options)

    # Logger.debug("#{inspect(http_result)}")

    # http_result
    # |> process_http_call_response(url, Enum.into(headers, %{}), encoded_body)
  end

  # defp process_http_call_response(
  #        {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}},
  #        url,
  #        request_headers,
  #        request_body
  #      )
  #      when status_code in 200..299 do
  #   %Response{
  #     request_url: url,
  #     request_headers: request_headers,
  #     request_body: request_body,
  #     status_code: status_code,
  #     response_body: response_body
  #   }
  # end

  # defp process_http_call_response(
  #        {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}},
  #        url,
  #        request_headers,
  #        request_body
  #      ) do
  #   %Response{
  #     request_url: url,
  #     request_headers: request_headers,
  #     request_body: request_body,
  #     status_code: status_code,
  #     response_body: response_body
  #   }
  # end

  # defp process_http_call_response(
  #        {:error, %HTTPoison.Error{} = httpoison_error},
  #        url,
  #        request_headers,
  #        request_body
  #      ) do
  #   %Response{
  #     request_url: url,
  #     request_headers: request_headers,
  #     request_body: request_body,
  #     client_error_message: HTTPoison.Error.message(httpoison_error)
  #   }
  # end
end
