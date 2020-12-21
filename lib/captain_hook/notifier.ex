defmodule CaptainHook.Notifier do
  @moduledoc false

  alias Ecto.Multi
  alias CaptainHook.Queue

  alias CaptainHook.Clients.HttpClient
  alias CaptainHook.Clients.Response

  alias CaptainHook.WebhookEndpoints
  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookNotifications
  alias CaptainHook.WebhookNotifications.WebhookNotification
  alias CaptainHook.WebhookConversations
  alias CaptainHook.WebhookConversations.WebhookConversation

  @spec notify(binary, boolean, binary, map, keyword) ::
          {:ok, WebhookNotification.t()} | {:error, Ecto.Changeset.t()}
  def notify(webhook, livemode?, notification_type, data, opts \\ [])
      when is_binary(webhook) and is_boolean(livemode?) and is_binary(notification_type) and
             is_map(data) and is_list(opts) do
    utc_now = DateTime.utc_now()

    webhook_endpoints =
      WebhookEndpoints.list_webhook_endpoints(
        filters: [webhook: webhook, livemode: livemode?, ongoing_at: utc_now]
      )

    webhook_result_handler =
      Keyword.get(opts, :webhook_result_handler)
      |> to_string_unless_nil()

    Multi.new()
    |> Multi.run(:webhook_notification, fn _repo, %{} ->
      WebhookNotifications.create_webhook_notification(%{
        created_at: utc_now,
        data: data,
        livemode: livemode?,
        resource_id: Keyword.get(opts, :resource_id) |> to_string_unless_nil(),
        resource_type: Keyword.get(opts, :resource_type) |> to_string_unless_nil(),
        type: notification_type,
        webhook: webhook
      })
    end)
    |> Multi.merge(fn %{webhook_notification: webhook_notification} ->
      webhook_endpoints
      |> Enum.reduce(Multi.new(), fn webhook_endpoint, acc ->
        acc
        |> Multi.run(:"enqueue_notify_endpoint_#{webhook_endpoint.id}", fn _repo, %{} ->
          enqueue_notify_endpoint!(webhook_notification, webhook_endpoint, webhook_result_handler)
        end)
      end)
    end)
    |> CaptainHook.repo().transaction()
    |> case do
      {:ok, %{webhook_notification: %WebhookNotification{} = webhook_notification}} ->
        CaptainHook.Queue.send_poll()
        {:ok, webhook_notification}

      {:error, :webhook_notification, changeset, _} ->
        {:error, changeset}
    end
  end

  defp enqueue_notify_endpoint!(
         %WebhookNotification{} = webhook_notification,
         %WebhookEndpoint{} = webhook_endpoint,
         webhook_result_handler
       ) do
    queue_name = "#{webhook_endpoint.webhook}_#{webhook_endpoint.id}"

    {:ok, _} =
      Queue.create_job(queue_name, "notify_endpoint", %{
        webhook_endpoint_id: webhook_endpoint.id,
        webhook_notification_id: webhook_notification.id,
        webhook_result_handler: webhook_result_handler
      })
  end

  @spec send_webhook_notification(
          map | WebhookEndpoint.t(),
          pos_integer | WebhookNotification.t()
        ) ::
          {:ok, binary | WebhookConversation.t()} | {:error, binary | Ecto.Changeset.t()}
  def send_webhook_notification(
        %{
          "webhook_endpoint_id" => webhook_endpoint_id,
          "webhook_notification_id" => webhook_notification_id,
          "webhook_result_handler" => webhook_result_handler
        },
        attempt_number
      ) do
    webhook_endpoint =
      WebhookEndpoints.get_webhook_endpoint!(webhook_endpoint_id,
        includes: [:enabled_notification_types]
      )

    webhook_notification = WebhookNotifications.get_webhook_notification!(webhook_notification_id)

    unless WebhookEndpoints.notification_type_enabled?(
             webhook_endpoint,
             webhook_notification.type
           ) do
      {:ok, :noop}
    else
      webhook_endpoint
      |> send_webhook_notification(webhook_notification)
      |> case do
        {:ok, webhook_conversation} ->
          if WebhookConversations.conversation_succeeded?(webhook_conversation) do
            {:ok, webhook_conversation}
          else
            handle_failure(webhook_result_handler, webhook_conversation, attempt_number)
            {:error, inspect(webhook_conversation)}
          end

        {:error, changeset} ->
          error = changeset |> AntlUtilsEcto.Changeset.errors_on() |> inspect()
          {:error, error}
      end
    end
  end

  def send_webhook_notification(
        %WebhookEndpoint{webhook: webhook_of_webhook_endpoint} = webhook_endpoint,
        %WebhookNotification{webhook: webhook_of_webhook_notification} = webhook_notification
      )
      when webhook_of_webhook_endpoint == webhook_of_webhook_notification do
    %{url: url, allow_insecure: allow_insecure} = webhook_endpoint

    headers = webhook_endpoint |> build_headers()
    body = webhook_endpoint |> build_body(webhook_notification)
    secrets = webhook_endpoint |> build_secrets()

    HttpClient.call(url, body, headers, secrets: secrets, allow_insecure: allow_insecure)
    |> to_webhook_conversation_attrs(webhook_endpoint, webhook_notification)
    |> WebhookConversations.create_webhook_conversation()
  end

  defp to_webhook_conversation_attrs(
         %Response{} = response,
         %WebhookEndpoint{id: webhook_endpoint_id},
         %WebhookNotification{id: webhook_notification_id}
       )
       when is_binary(webhook_endpoint_id) do
    status =
      if response.status in 200..299,
        do: WebhookConversation.status().success,
        else: WebhookConversation.status().failed

    %{
      webhook_endpoint_id: webhook_endpoint_id,
      webhook_notification_id: webhook_notification_id,
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
         %WebhookEndpoint{livemode: livemode?},
         %WebhookNotification{} = webhook_notification
       ) do
    %{
      id: webhook_notification.id,
      type: webhook_notification.type,
      livemode: livemode?,
      data: webhook_notification.data
    }
  end

  defp build_secrets(%WebhookEndpoint{} = webhook_endpoint) do
    webhook_endpoint
    |> WebhookEndpoints.Secrets.list_webhook_endpoint_secrets()
    |> case do
      [] ->
        nil

      webhook_secrets ->
        webhook_secrets
        |> Enum.sort_by(&{&1.is_main, &1.started_at})
        |> Enum.map(& &1.secret)
    end
  end

  defp to_string_unless_nil(nil), do: nil
  defp to_string_unless_nil(value), do: to_string(value)
end
