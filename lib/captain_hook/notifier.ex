defmodule CaptainHook.Notifier do
  @moduledoc false

  alias Ecto.Multi
  alias CaptainHook.Queuetopia

  alias CaptainHook.Clients.HttpClient
  alias CaptainHook.Clients.Response

  alias CaptainHook.WebhookEndpoints
  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookNotifications
  alias CaptainHook.WebhookNotifications.WebhookNotification
  alias CaptainHook.WebhookConversations
  alias CaptainHook.WebhookConversations.WebhookConversation

  @spec notify(binary | [binary], boolean, binary, map, keyword) ::
          {:ok, [WebhookNotification.t()]} | {:error, Ecto.Changeset.t()}
  def notify(topic, livemode?, notification_type, data, opts \\ [])
      when is_boolean(livemode?) and is_binary(notification_type) and
             is_map(data) and is_list(opts) do
    create_webhook_notifications(topic, livemode?, notification_type, data, opts)
    |> case do
      {:ok, webhook_notifications} ->
        webhook_notifications
        |> Enum.map(fn webhook_notification ->
          webhook_notification |> send_webhook_notification()
        end)

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @spec async_notify(binary | [binary], boolean, binary, map, keyword) ::
          {:ok, [WebhookNotification.t()]} | {:error, Ecto.Changeset.t()}
  def async_notify(topic, livemode?, notification_type, data, opts \\ [])
      when is_boolean(livemode?) and is_binary(notification_type) and
             is_map(data) and is_list(opts) do
    Multi.new()
    |> Multi.run(:webhook_notifications, fn _, %{} ->
      create_webhook_notifications(topic, livemode?, notification_type, data, opts)
    end)
    |> Multi.run(
      :enqueue_webhook_notifications,
      fn _, %{webhook_notifications: webhook_notifications} ->
        webhook_result_handler = Keyword.get(opts, :webhook_result_handler) |> stringify()

        webhook_notifications
        |> Enum.reduce(Multi.new(), fn webhook_notification, acc ->
          acc
          |> Multi.run(:"enqueue_webhook_notification_#{webhook_notification.id}", fn _, %{} ->
            webhook_notification =
              WebhookNotifications.get_webhook_notification!(webhook_notification.id,
                includes: [:webhook_endpoint]
              )

            {:ok, enqueue_notify_endpoint!(webhook_notification, webhook_result_handler)}
          end)
        end)
      end
    )
    |> CaptainHook.repo().transaction()
    |> case do
      {:ok, changes} ->
        CaptainHook.Queuetopia.handle_event(:new_incoming_job)
        {:ok, get_webhook_notifications_from_multi_changes(changes)}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  @spec create_webhook_notifications(binary | [binary], boolean, binary, map, keyword) ::
          {:ok, [WebhookNotification.t()]} | {:error, Ecto.Changeset.t()}
  def create_webhook_notifications(topic, livemode?, notification_type, data, opts \\ [])
      when is_boolean(livemode?) and is_binary(notification_type) and
             is_map(data) and is_list(opts) do
    utc_now = DateTime.utc_now()
    topics = topic |> List.wrap() |> Enum.uniq()

    Multi.new()
    |> notify_topics_multi(topics, livemode?, notification_type, data, utc_now, opts)
    |> CaptainHook.repo().transaction()
    |> case do
      {:ok, changes} ->
        {:ok, get_webhook_notifications_from_multi_changes(changes)}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
  end

  defp notify_topics_multi(multi, topics, livemode?, notification_type, data, created_at, opts) do
    topics
    |> Enum.reduce(multi, fn topic, acc ->
      acc
      |> notify_topic_multi(topic, livemode?, notification_type, data, created_at, opts)
    end)
  end

  defp notify_topic_multi(multi, topic, livemode?, notification_type, data, created_at, opts) do
    webhook_endpoints =
      WebhookEndpoints.list_webhook_endpoints(
        filters: [topic: topic, livemode: livemode?, ongoing_at: created_at]
      )

    webhook_endpoints
    |> Enum.reduce(multi, fn webhook_endpoint, acc ->
      notification_type_enabled? =
        WebhookEndpoints.notification_type_enabled?(webhook_endpoint, notification_type)

      unless notification_type_enabled? do
        acc
      else
        acc
        |> notify_webhook_endpoint_multi(
          webhook_endpoint,
          notification_type,
          data,
          created_at,
          opts
        )
      end
    end)
  end

  defp notify_webhook_endpoint_multi(
         %Ecto.Multi{} = multi,
         %WebhookEndpoint{} = webhook_endpoint,
         notification_type,
         data,
         %DateTime{} = created_at,
         opts
       ) do
    multi
    |> get_or_create_webhook_notification_multi(
      webhook_endpoint,
      notification_type,
      data,
      created_at,
      opts
    )
  end

  defp get_or_create_webhook_notification_multi(
         %Ecto.Multi{} = multi,
         %WebhookEndpoint{} = webhook_endpoint,
         notification_type,
         data,
         %DateTime{} = created_at,
         opts
       ) do
    idempotency_key = Keyword.get(opts, :idempotency_key, Ecto.UUID.generate())

    multi
    |> Multi.run(:"webhook_notification_by_#{idempotency_key}", fn _, %{} ->
      WebhookNotifications.get_webhook_notification_by(idempotency_key: idempotency_key)
    end)
    |> Multi.run(:"webhook_notification_for_#{webhook_endpoint.id}", fn _repo, changes ->
      webhook_notification = Map.fetch!(changes, :"webhook_notification_by_#{idempotency_key}")

      if webhook_notification do
        {:ok, webhook_notification}
      else
        WebhookNotifications.create_webhook_notification(%{
          created_at: created_at,
          data: data,
          idempotency_key: idempotency_key,
          resource_id: Keyword.get(opts, :resource_id) |> stringify(),
          resource_type: Keyword.get(opts, :resource_type) |> stringify(),
          type: notification_type,
          webhook_endpoint_id: webhook_endpoint.id
        })
      end
    end)
  end

  defp enqueue_notify_endpoint!(
         %WebhookNotification{webhook_endpoint: webhook_endpoint} = webhook_notification,
         webhook_result_handler
       ) do
    queue_name = "#{webhook_endpoint.topic}_#{webhook_endpoint.id}"

    {:ok, _} =
      Queuetopia.create_job(queue_name, "notify_endpoint", %{
        webhook_notification_id: webhook_notification.id,
        webhook_result_handler: webhook_result_handler
      })
  end

  defp get_webhook_notifications_from_multi_changes(changes) when is_map(changes) do
    changes
    |> Enum.filter(fn {key, _value} ->
      key |> to_string() |> String.starts_with?("webhook_notification_for")
    end)
    |> Enum.map(fn {_key, value} -> value end)
    |> Enum.reject(&is_nil/1)
    |> case do
      webhook_notifications -> {:ok, webhook_notifications}
    end
  end

  @spec send_webhook_notification(
          map | WebhookEndpoint.t(),
          pos_integer | WebhookNotification.t()
        ) ::
          {:ok, binary | WebhookConversation.t()} | {:error, binary | Ecto.Changeset.t()}
  def send_webhook_notification(
        %{
          "webhook_notification_id" => webhook_notification_id,
          "webhook_result_handler" => webhook_result_handler
        },
        attempt_number
      ) do
    webhook_notification_id
    |> WebhookNotifications.get_webhook_notification!()
    |> send_webhook_notification()
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

  def send_webhook_notification(%WebhookNotification{succeeded_at: nil} = webhook_notification) do
    %{webhook_endpoint: webhook_endpoint} =
      WebhookNotifications.get_webhook_notification!(webhook_notification.id,
        includes: [webhook_endpoint: :enabled_notification_types]
      )

    %{url: url, is_insecure_allowed: is_insecure_allowed} = webhook_endpoint

    headers = webhook_endpoint |> build_headers()
    body = webhook_endpoint |> build_body(webhook_notification)
    secrets = webhook_endpoint |> build_secrets()

    HttpClient.call(url, body, headers, secrets: secrets, is_insecure_allowed: is_insecure_allowed)
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
        do: WebhookConversation.statuses().succeeded,
        else: WebhookConversation.statuses().failed

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
         %WebhookEndpoint{id: webhook_endpoint_id, livemode: livemode?},
         %WebhookNotification{} = webhook_notification
       ) do
    %{
      id: webhook_notification.id,
      type: webhook_notification.type,
      livemode: livemode?,
      endpoint_id: webhook_endpoint_id,
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

  defp stringify(nil), do: nil
  defp stringify(value), do: to_string(value)
end
