defmodule CaptainHook.Queue.JobPerformer do
  @behaviour Queuetopia.Jobs.Performer

  alias AntlUtils.Ecto.Changeset, as: AntlUtilsEctoChangeset
  alias CaptainHook.Clients.Response
  alias CaptainHook.WebhookEndpoints
  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookConversations
  alias CaptainHook.WebhookConversations.WebhookConversation

  @performer __MODULE__ |> to_string
  @webhook_client Application.get_env(
                    :captain_hook,
                    :http_client,
                    CaptainHook.Clients.HttpClient
                  )

  @impl true
  @spec perform(Queuetopia.Jobs.Job.t()) ::
          {:error, binary} | {:ok, CaptainHook.WebhookConversations.WebhookConversation.t()}
  def perform(%Queuetopia.Jobs.Job{
        performer: @performer,
        action: action,
        params: params,
        attempts: attempt_number
      }) do
    send_notification(action, params, attempt_number)
  end

  @spec send_notification(binary, map, integer) ::
          {:error, binary} | {:ok, CaptainHook.WebhookConversations.WebhookConversation.t()}
  def send_notification(action, params, attempt_number)
      when is_binary(action) and is_map(params) and is_integer(attempt_number) do
    params = Recase.Enumerable.atomize_keys(params, &Recase.to_snake/1)

    data_wrapper = struct!(CaptainHook.DataWrapper, Map.to_list(params))

    webhook_endpoint =
      WebhookEndpoints.get_webhook_endpoint!(
        data_wrapper.webhook,
        data_wrapper.webhook_endpoint_id
      )

    webhook_conversation_attrs =
      webhook_endpoint
      |> notify_endpoint(data_wrapper.request_id, data_wrapper.data)
      |> webhook_conversation_attrs(webhook_endpoint, data_wrapper)

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

  defp notify_endpoint(%WebhookEndpoint{} = webhook_endpoint, request_id, data)
       when is_binary(request_id) and is_map(data) do
    metadata = Map.get(webhook_endpoint, :metadata) || %{}
    headers = Map.get(webhook_endpoint, :headers) || %{}
    params = data |> Map.merge(metadata) |> Map.put(:request_id, request_id)

    @webhook_client.call(webhook_endpoint.url, params, headers)
  end

  defp webhook_conversation_attrs(
         %Response{} = response,
         %WebhookEndpoint{id: webhook_endpoint_id},
         %CaptainHook.DataWrapper{} = data_wrapper
       )
       when is_binary(webhook_endpoint_id) do
    status =
      if response.status_code in 200..299,
        do: WebhookConversation.status().success,
        else: WebhookConversation.status().failed

    %{
      webhook_endpoint_id: webhook_endpoint_id,
      schema_type: data_wrapper.schema_type,
      schema_id: data_wrapper.schema_id,
      request_id: data_wrapper.request_id |> AntlUtils.Ecto.UUID.to_uuid(),
      requested_at: response.requested_at,
      request_url: response.request_url,
      request_headers: response.request_headers,
      request_body: response.request_body,
      http_status: response.status_code,
      response_body: response.response_body,
      client_error_message: response.client_error_message,
      status: status
    }
  end

  defp handle_failure(
         webhook_result_handler,
         %WebhookConversation{} = webhook_conversation,
         attemps
       ) do
    if webhook_result_handler do
      handler_module(webhook_result_handler).handle_failure(webhook_conversation, attemps)
    end
  end

  defp handler_module(webhook_result_handler) when is_binary(webhook_result_handler) do
    webhook_result_handler
    |> String.split(".")
    |> Module.safe_concat()
  end
end
