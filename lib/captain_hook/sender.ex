defmodule CaptainHook.Sender do
  alias CaptainHook.Queue

  alias AntlUtilsEcto.Changeset, as: AntlUtilsEctoChangeset

  alias CaptainHook.DataWrapper
  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.Clients.Response
  alias CaptainHook.WebhookEndpoints
  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookConversations
  alias CaptainHook.WebhookConversations.WebhookConversation
  alias CaptainHook.WebhookSecrets
  alias CaptainHook.WebhookSecrets.WebhookSecret

  @http_client Application.get_env(:captain_hook, :http_client, CaptainHook.Clients.HttpClient)

  def enqueue_event(
        %WebhookEndpoint{} = webhook_endpoint,
        notification_type,
        {resource_type, resource_id},
        data,
        opts \\ []
      ) do
    data_wrapper =
      DataWrapper.new(
        webhook_endpoint.id,
        notification_type,
        resource_type,
        resource_id,
        data,
        opts
      )
      |> Map.from_struct()

    queue_name = "#{webhook_endpoint.webhook}_#{webhook_endpoint.id}"

    {:ok, _} = Queue.create_job(queue_name, "notify", data_wrapper)
  end

  def perform_send(raw_data_wrapper, attempt_number) when is_map(raw_data_wrapper) do
    raw_data_wrapper = raw_data_wrapper |> Recase.Enumerable.atomize_keys(&Recase.to_snake/1)
    data_wrapper = struct!(DataWrapper, Map.to_list(raw_data_wrapper))

    webhook_endpoint = WebhookEndpoints.get_webhook_endpoint!(data_wrapper.webhook_endpoint_id)

    performing_request_datetime = DateTime.utc_now()

    secrets =
      webhook_endpoint
      |> WebhookSecrets.list_webhook_secrets()
      |> Enum.sort_by(&{&1.main?, &1.started_at})
      |> Enum.map(& &1.secret)

    body = %{
      id: data_wrapper.notification_id,
      type: data_wrapper.notification_type,
      livemode: webhook_endpoint.livemode,
      data: data_wrapper.data,
      metadata: webhook_endpoint.metadata
    }

    request_datetime = DateTime.utc_now()

    headers =
      (webhook_endpoint.headers || %{})
      |> Map.put("Signature", build_signature(body, DateTime.to_unix(request_datetime), secrets))

    %Response{} =
      response = do_send(webhook_endpoint.url, body, headers, webhook_endpoint.allow_insecure)

    webhook_conversation_attrs =
      webhook_conversation_attrs(response, webhook_endpoint, data_wrapper, request_datetime)

    webhook_endpoint
    |> WebhookConversations.create_webhook_conversation(webhook_conversation_attrs)
    |> case do
      {:ok, webhook_conversation} ->
        if WebhookConversations.conversation_succeeded?(webhook_conversation) do
          {:ok, webhook_conversation}
        else
          handle_failure(
            data_wrapper.webhook_result_handler,
            webhook_conversation,
            attempt_number
          )

          error = webhook_conversation |> inspect()
          {:error, error}
        end

      {:error, changeset} ->
        error = changeset |> AntlUtilsEctoChangeset.errors_on() |> inspect()
        {:error, error}
    end
  end

  defp do_send(url, body, headers, allow_insecure) do
    @http_client.call(url, body, headers, allow_insecure: allow_insecure)
  end

  defp build_signature(body, timestamp, secrets) do
    signature = "t=#{timestamp},"
    body = Jason.encode!(body)

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

  # @spec send_notification(binary, map, integer) ::
  #         {:error, binary} | {:ok, CaptainHook.WebhookConversations.WebhookConversation.t()}
  # def send_notification(action, params, attempt_number)
  #     when is_binary(action) and is_map(params) and is_integer(attempt_number) do
  #   params = Recase.Enumerable.atomize_keys(params, &Recase.to_snake/1)

  #   data_wrapper = struct!(CaptainHook.DataWrapper, Map.to_list(params))

  #   webhook_endpoint =
  #     WebhookEndpoints.get_webhook_endpoint!(
  #       data_wrapper.webhook,
  #       data_wrapper.webhook_endpoint_id
  #     )

  #   ongoing_webhook_secrets =
  #     WebhookSecrets.list_webhook_secrets(webhook_endpoint)
  #     |> WebhookSecrets.filter_webhook_secrets(:ongoing, DateTime.utc_now())

  #   request_datetime = DateTime.utc_now()

  #   webhook_conversation_attrs =
  #     webhook_endpoint
  #     |> notify_endpoint(
  #       data_wrapper.request_id,
  #       data_wrapper.data,
  #       request_datetime,
  #       ongoing_webhook_secrets
  #     )
  #     |> webhook_conversation_attrs(webhook_endpoint, data_wrapper, request_datetime)

  #   webhook_endpoint
  #   |> WebhookConversations.create_webhook_conversation(webhook_conversation_attrs)
  #   |> case do
  #     {:ok, webhook_conversation} ->
  #       if WebhookConversations.conversation_succeeded?(webhook_conversation) do
  #         {:ok, webhook_conversation}
  #       else
  #         handle_failure(
  #           data_wrapper.webhook_result_handler,
  #           webhook_conversation,
  #           attempt_number
  #         )

  #         error = webhook_conversation |> inspect()
  #         {:error, error}
  #       end

  #     {:error, changeset} ->
  #       error = changeset |> AntlUtilsEctoChangeset.errors_on() |> inspect()
  #       {:error, error}
  #   end
  # end

  # defp notify_endpoint(
  #        %WebhookEndpoint{
  #          url: url,
  #          metadata: metadata,
  #          headers: headers,
  #          allow_insecure: allow_insecure
  #        },
  #        request_id,
  #        data,
  #        %DateTime{} = request_datetime,
  #        webhook_secrets
  #      )
  #      when is_binary(request_id) and is_map(data)
  #      when is_list(webhook_secrets) do
  #   metadata = metadata || %{}
  #   params = data |> Map.merge(metadata) |> Map.put(:request_id, request_id)
  #   signature = build_signature(request_datetime, params, webhook_secrets)
  #   headers = (headers || %{}) |> Map.put("CaptainHook-Signature", signature)

  #   @webhook_client.call(url, params, headers, allow_insecure: allow_insecure)
  # end

  # defp webhook_conversation_attrs(
  #        %Response{} = response,
  #        %WebhookEndpoint{id: webhook_endpoint_id},
  #        %CaptainHook.DataWrapper{} = data_wrapper,
  #        %DateTime{} = requested_at
  #      )
  #      when is_binary(webhook_endpoint_id) do
  #   status =
  #     if response.status_code in 200..299,
  #       do: WebhookConversation.status().success,
  #       else: WebhookConversation.status().failed

  #   %{
  #     webhook_endpoint_id: webhook_endpoint_id,
  #     resource_type: data_wrapper.resource_type,
  #     resource_id: data_wrapper.resource_id,
  #     request_id: data_wrapper.request_id,
  #     requested_at: requested_at,
  #     request_url: response.request_url,
  #     request_headers: response.request_headers,
  #     request_body: response.request_body,
  #     http_status: response.status_code,
  #     response_body: response.response_body,
  #     client_error_message: response.client_error_message,
  #     status: status
  #   }
  # end

  # defp handle_failure(
  #        webhook_result_handler,
  #        %WebhookConversation{} = webhook_conversation,
  #        attemps
  #      ) do
  #   if webhook_result_handler do
  #     handler_module(webhook_result_handler).handle_failure(webhook_conversation, attemps)
  #   end
  # end

  # defp handler_module(webhook_result_handler) when is_binary(webhook_result_handler) do
  #   webhook_result_handler
  #   |> String.split(".")
  #   |> Module.safe_concat()
  # end

  defp ignore?() do
    true
  end
end
