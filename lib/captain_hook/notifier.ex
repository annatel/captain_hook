defmodule CaptainHook.Notifier do
  alias CaptainHook.Queue

  alias CaptainHook.Clients.HttpClient

  alias AntlUtilsEcto.Changeset, as: AntlUtilsEctoChangeset

  alias CaptainHook.DataWrapper
  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.Clients.Response
  alias CaptainHook.WebhookEndpoints
  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookConversations
  alias CaptainHook.WebhookConversations.WebhookConversation
  alias CaptainHook.WebhookSecrets

  @spec enqueue_event(WebhookEndpoint.t(), binary, {atom, any}, map, keyword) ::
          {:ok, Queuetopia.Jobs.Job.t()}
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

  @spec notify(map, pos_integer) :: {:ok, WebhookConversation.t()} | {:error, binary()}
  def notify(raw_data_wrapper, attempt_number) when is_map(raw_data_wrapper) do
    raw_data_wrapper = raw_data_wrapper |> Recase.Enumerable.atomize_keys(&Recase.to_snake/1)
    data_wrapper = struct!(DataWrapper, Map.to_list(raw_data_wrapper))

    %{url: url, allow_insecure: allow_insecure} =
      webhook_endpoint = WebhookEndpoints.get_webhook_endpoint!(data_wrapper.webhook_endpoint_id)

    headers = webhook_endpoint |> build_headers()
    body = webhook_endpoint |> build_body(data_wrapper)
    secrets = webhook_endpoint |> build_secrets()

    HttpClient.call(url, body, headers, secrets: secrets, allow_insecure: allow_insecure)
    |> to_webhook_conversation_attrs(webhook_endpoint, data_wrapper)
    |> WebhookConversations.create_webhook_conversation()
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

          {:error, inspect(webhook_conversation)}
        end

      {:error, changeset} ->
        error = changeset |> AntlUtilsEctoChangeset.errors_on() |> inspect()
        {:error, error}
    end
  end

  defp to_webhook_conversation_attrs(
         %Response{} = response,
         %WebhookEndpoint{id: webhook_endpoint_id},
         %CaptainHook.DataWrapper{} = data_wrapper
       )
       when is_binary(webhook_endpoint_id) do
    status =
      if response.status in 200..299,
        do: WebhookConversation.status().success,
        else: WebhookConversation.status().failed

    %{
      webhook_endpoint_id: webhook_endpoint_id,
      resource_type: data_wrapper.resource_type,
      resource_id: data_wrapper.resource_id,
      notification_id: data_wrapper.notification_id,
      notification_type: data_wrapper.notification_type,
      requested_at: response.requested_at,
      request_url: response.request_url,
      request_headers: response.request_headers,
      request_body: response.request_body,
      http_status: response.status,
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

  defp build_headers(%WebhookEndpoint{headers: headers}) do
    headers || %{}
  end

  defp build_body(
         %WebhookEndpoint{livemode: livemode?, metadata: metadata},
         %CaptainHook.DataWrapper{} = data_wrapper
       ) do
    %{
      id: data_wrapper.notification_id,
      type: data_wrapper.notification_type,
      livemode: livemode?,
      data: data_wrapper.data,
      metadata: metadata
    }
  end

  defp build_secrets(%WebhookEndpoint{} = webhook_endpoint) do
    webhook_endpoint
    |> WebhookSecrets.list_webhook_secrets()
    |> case do
      [] ->
        nil

      webhook_secrets ->
        webhook_secrets
        |> Enum.sort_by(&{&1.main?, &1.started_at})
        |> Enum.map(& &1.secret)
    end
  end
end
