defmodule CaptainHook.Clients.HttpClientTest do
  use CaptainHook.DataCase, async: true

  alias CaptainHook.Clients.HttpClient
  alias CaptainHook.Clients.Response

  setup do
    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "success call, returns a valid Response", %{bypass: bypass} do
    start_supervised!(CaptainHook.Supervisor)

    Bypass.expect_once(bypass, "POST", "/", fn conn ->
      Plug.Conn.resp(conn, 200, "")
    end)

    headers = %{"firstHeader" => "value", "second_header" => "value", "third-header" => "value"}
    body = %{}
    encoded_body = Jason.encode!(body)
    url = endpoint_url(bypass.port)

    assert %Response{
             request_url: ^url,
             request_headers: headers,
             request_body: ^encoded_body,
             response_body: "",
             response_http_status: 200
           } = HttpClient.call(url, body, headers)

    assert Map.get(headers, "content-type") == "application/json"

    assert Map.get(headers, "user-agent") ==
             "CaptainHook/1.0; +(https://github.com/annatel/captain_hook)"

    assert Map.get(headers, "first-header") == "value"
    assert Map.get(headers, "second-header") == "value"
    assert Map.get(headers, "third-header") == "value"
  end

  test "when secret is nil, do not add the signature header", %{bypass: bypass} do
    start_supervised!(CaptainHook.Supervisor)

    Bypass.expect_once(bypass, "POST", "/", fn conn ->
      Plug.Conn.resp(conn, 200, "")
    end)

    assert %Response{request_headers: headers} =
             HttpClient.call(endpoint_url(bypass.port), %{}, %{}, secrets: nil)

    refute Map.has_key?(headers, "Signature")
  end

  test "when secret is not nil, add the signature header", %{bypass: bypass} do
    start_supervised!(CaptainHook.Supervisor)
    body = %{}
    encoded_body = Jason.encode!(body)
    secret = "secret"
    signature = CaptainHookSignature.sign(encoded_body, System.system_time(:second), secret)

    Bypass.expect_once(bypass, "POST", "/", fn conn ->
      assert signature == conn.req_headers |> Enum.into(%{}) |> Map.get("signature")
      Plug.Conn.resp(conn, 200, "")
    end)

    assert %Response{request_headers: headers} =
             HttpClient.call(endpoint_url(bypass.port), body, %{}, secrets: secret)

    assert Map.has_key?(headers, "signature")
  end

  test "http call return an http error", %{bypass: bypass} do
    start_supervised!(CaptainHook.Supervisor)

    Bypass.expect_once(bypass, "POST", "/", fn conn ->
      Plug.Conn.resp(conn, 429, ~s<{"errors": [{"code": 88, "message": "Rate limit exceeded"}]}>)
    end)

    headers = %{}
    body = %{}
    encoded_body = Jason.encode!(body)
    url = endpoint_url(bypass.port)

    assert %Response{
             request_url: ^url,
             request_body: ^encoded_body,
             response_http_status: 429,
             response_body: "{\"errors\": [{\"code\": 88, \"message\": \"Rate limit exceeded\"}]}"
           } = HttpClient.call(url, body, headers)
  end

  test "when the url is invalid, return a Response with a client_error_message" do
    start_supervised!(CaptainHook.Supervisor)

    headers = %{}
    body = %{}
    encoded_body = Jason.encode!(body)

    assert %Response{
             request_url: "http://url",
             request_body: ^encoded_body,
             response_body: nil,
             response_http_status: nil,
             client_error_message: "non-existing domain"
           } = HttpClient.call("http://url", body, headers)
  end

  test "when the ssl is expired, returns a Response with a client_error_messsage" do
    start_supervised!(CaptainHook.Supervisor)

    headers = %{}
    body = %{}
    encoded_body = Jason.encode!(body)

    assert %Response{
             request_url: "https://expired.badssl.com/",
             request_body: ^encoded_body,
             response_body: nil,
             response_http_status: nil,
             client_error_message: client_error_message
           } = HttpClient.call("https://expired.badssl.com/", body, headers)

    assert client_error_message =~ "CLIENT ALERT: Fatal - Certificate Expired"
  end

  test "when is_insecure_allowed is true and the ssl is expired, returns a success Response" do
    start_supervised!(CaptainHook.Supervisor)

    headers = %{}
    body = %{}
    encoded_body = Jason.encode!(body)

    assert %Response{
             request_url: "https://expired.badssl.com/",
             request_body: ^encoded_body,
             response_body:
               "<html>\r\n<head><title>405 Not Allowed</title></head>\r\n<body bgcolor=\"white\">\r\n<center><h1>405 Not Allowed</h1></center>\r\n<hr><center>nginx/1.10.3 (Ubuntu)</center>\r\n</body>\r\n</html>\r\n",
             response_http_status: 405
           } =
             HttpClient.call("https://expired.badssl.com/", body, headers,
               is_insecure_allowed: true
             )
  end

  defp endpoint_url(port), do: "http://localhost:#{port}/"
end
