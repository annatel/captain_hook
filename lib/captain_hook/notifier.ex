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

  @spec notify(binary, boolean, binary, map, keyword) ::
          {:ok, [WebhookNotification.t()]} | {:error, Ecto.Changeset.t()}
  def notify(owner_id, livemode?, notification_ref, data, opts \\ [])
      when is_boolean(livemode?) and is_binary(notification_ref) and
             is_map(data) and is_list(opts) do
    with {:ok, webhook_notifications} <-
           create_webhook_notifications(owner_id, livemode?, notification_ref, data, opts) do
      send_webhook_notifications(webhook_notifications)
    end
  end

  @spec async_notify(binary, boolean, binary, map, keyword) ::
          {:ok, [WebhookNotification.t()]} | {:error, Ecto.Changeset.t()}
  def async_notify(owner_id, livemode?, notification_ref, data, opts \\ [])
      when is_boolean(livemode?) and is_binary(notification_ref) and
             is_map(data) and is_list(opts) do
    Multi.new()
    |> Multi.run(:webhook_notifications, fn _, %{} ->
      create_webhook_notifications(owner_id, livemode?, notification_ref, data, opts)
    end)
    |> Multi.merge(fn
      %{webhook_notifications: []} ->
        Multi.new()

      %{webhook_notifications: webhook_notifications} ->
        webhook_result_handler = Keyword.get(opts, :webhook_result_handler) |> stringify()

        webhook_notifications
        |> Enum.reduce(Multi.new(), fn webhook_notification, acc ->
          acc
          |> Multi.run(
            :"enqueue_webhook_notification_#{webhook_notification.id}",
            fn _repo, %{} ->
              {:ok, enqueue_notify_endpoint!(webhook_notification, webhook_result_handler)}
            end
          )
        end)
    end)
    |> CaptainHook.repo().transaction()
    |> case do
      {:ok, %{webhook_notifications: webhook_notifications}} ->
        {:ok, webhook_notifications}

      {:error, _, changeset, _} ->
        {:error, changeset}
    end
    |> tap(fn _ -> CaptainHook.Queuetopia.handle_event(:new_incoming_job) end)
  end

  defp create_webhook_notifications(owner_id, livemode?, notification_ref, data, opts)
       when is_boolean(livemode?) and is_binary(notification_ref) and
              is_map(data) and is_list(opts) do
    utc_now = DateTime.utc_now()

    owner_id_field = elem(CaptainHook.owner_id_field(:schema), 0)

    filters =
      [livemode: livemode?]
      |> Keyword.put(owner_id_field, owner_id)

    webhook_endpoints =
      WebhookEndpoints.list_webhook_endpoints(
        filters: filters,
        includes: [:enabled_notification_patterns]
      )

    webhook_endpoints
    |> Enum.reduce(Multi.new(), fn webhook_endpoint, acc ->
      if should_be_notified?(webhook_endpoint, notification_ref) do
        acc
        |> Multi.run(
          :"webhook_notification_for_#{webhook_endpoint.id}",
          fn _, %{} ->
            create_webhook_notification(webhook_endpoint, notification_ref, data, utc_now, opts)
          end
        )
      else
        acc
      end
    end)
    |> CaptainHook.repo().transaction()
    |> case do
      {:ok, changes} -> {:ok, get_webhook_notifications_from_multi_changes(changes)}
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  defp should_be_notified?(%WebhookEndpoint{} = webhook_endpoint, notification_ref),
    do:
      WebhookEndpoints.webhook_endpoint_enabled?(webhook_endpoint) &&
        WebhookEndpoints.notification_ref_enabled?(webhook_endpoint, notification_ref)

  defp create_webhook_notification(
         %WebhookEndpoint{} = webhook_endpoint,
         notification_ref,
         data,
         %DateTime{} = created_at,
         opts
       ) do
    Multi.new()
    |> Multi.put(:idempotency_key, Keyword.get(opts, :idempotency_key))
    |> Multi.put(:webhook_endpoint_id, webhook_endpoint.id)
    |> Multi.run(:lock_idempotency_key_by_webhook_endpoint, fn
      _, %{idempotency_key: nil} ->
        {:ok, nil}

      _, %{idempotency_key: idempotency_key, webhook_endpoint_id: webhook_endpoint_id} ->
        {:ok, Padlock.Mutexes.lock!("captain_hook_#{webhook_endpoint_id}_#{idempotency_key}")}
    end)
    |> Multi.run(:original_webhook_notification, fn
      _, %{idempotency_key: nil} ->
        {:ok, nil}

      _, %{idempotency_key: idempotency_key, webhook_endpoint_id: webhook_endpoint_id} ->
        {:ok,
         WebhookNotifications.get_webhook_notification_by([idempotency_key: idempotency_key],
           filters: [webhook_endpoint_id: webhook_endpoint_id]
         )}
    end)
    |> Multi.run(:webhook_notification, fn
      _, %{original_webhook_notification: %WebhookNotification{} = webhook_notification} ->
        {:ok, webhook_notification}

      _, %{original_webhook_notification: nil, idempotency_key: idempotency_key} ->
        WebhookNotifications.create_webhook_notification(%{
          created_at: created_at,
          data: data,
          idempotency_key: idempotency_key,
          ref: notification_ref,
          resource_id: Keyword.get(opts, :resource_id) |> stringify(),
          resource_object: Keyword.get(opts, :resource_object) |> stringify(),
          webhook_endpoint_id: webhook_endpoint.id
        })
    end)
    |> CaptainHook.repo().transaction()
    |> case do
      {:ok, %{webhook_notification: webhook_notification}} -> {:ok, webhook_notification}
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  defp enqueue_notify_endpoint!(
         %WebhookNotification{} = webhook_notification,
         webhook_result_handler
       ) do
    {:ok, res} =
      Queuetopia.create_job(
        "#{webhook_notification.webhook_endpoint_id}",
        "notify_endpoint",
        %{
          webhook_notification_id: webhook_notification.id,
          webhook_result_handler: webhook_result_handler
        }
      )

    res
  end

  defp get_webhook_notifications_from_multi_changes(changes) when is_map(changes) do
    changes
    |> Enum.filter(fn {key, _value} ->
      key |> to_string() |> String.starts_with?("webhook_notification_for")
    end)
    |> Enum.map(fn {_key, value} -> value end)
    |> Enum.reject(&is_nil/1)
  end

  defp send_webhook_notifications(webhook_notifications) do
    results = webhook_notifications |> Enum.map(&send_webhook_notification/1)

    with nil <- first_error(results) do
      {:ok, results |> Enum.map(&elem(&1, 1))}
    end
  end

  defp first_error(results) do
    Enum.find(results, &match?({:error, _}, &1))
  end

  @spec send_webhook_notification(map) :: {:ok, WebhookNotification.t()} | {:error, binary}
  def send_webhook_notification(%{"webhook_notification_id" => webhook_notification_id}) do
    webhook_notification_id
    |> WebhookNotifications.get_webhook_notification!(includes: [:webhook_endpoint])
    |> send_webhook_notification()
  end

  @spec send_webhook_notification(WebhookNotification.t()) ::
          {:ok, WebhookNotification.t()} | {:error, binary}
  def send_webhook_notification(%WebhookNotification{} = webhook_notification) do
    %{webhook_endpoint: webhook_endpoint} =
      webhook_notification |> CaptainHook.repo().preload([:webhook_endpoint])

    if WebhookEndpoints.webhook_endpoint_enabled?(webhook_endpoint) do
      %{webhook_notification: webhook_notification, webhook_conversation: webhook_conversation} =
        webhook_notification |> send_webhook_notification!()

      if WebhookNotifications.notification_succeeded?(webhook_notification) do
        {:ok, webhook_notification}
      else
        {:error, Jason.encode!(webhook_conversation)}
      end
    else
      {:ok, :webhook_endpoint_is_disabled}
    end
  end

  defp send_webhook_notification!(%WebhookNotification{succeeded_at: nil} = webhook_notification) do
    %{webhook_endpoint: webhook_endpoint} =
      WebhookNotifications.get_webhook_notification!(webhook_notification.id,
        includes: [:webhook_endpoint]
      )

    %{url: url, is_insecure_allowed: is_insecure_allowed} = webhook_endpoint

    headers = webhook_endpoint |> build_headers()
    body = webhook_notification |> build_body()
    secrets = webhook_endpoint |> build_secrets()

    response =
      HttpClient.call(url, body, headers,
        secrets: secrets,
        is_insecure_allowed: is_insecure_allowed
      )

    webhook_conversation =
      save_webhook_conversation!(response, webhook_endpoint, webhook_notification)

    if WebhookConversations.conversation_succeeded?(webhook_conversation) do
      %{
        webhook_notification: set_webhook_notification_as_successful!(webhook_notification),
        webhook_conversation: webhook_conversation
      }
    else
      %{
        webhook_notification: webhook_notification,
        webhook_conversation: webhook_conversation
      }
    end
  end

  defp send_webhook_notification!(%WebhookNotification{} = webhook_notification) do
    %{webhook_notification: webhook_notification, webhook_conversation: nil}
  end

  @spec handle_failure!(map, integer, %DateTime{}, binary) :: :ok
  def handle_failure!(
        %{
          "webhook_notification_id" => webhook_notification_id,
          "webhook_result_handler" => webhook_result_handler
        },
        attempt,
        next_retry_at,
        error
      ) do
    webhook_conversation = WebhookConversation.new!(Jason.decode!(error))

    %{webhook_endpoint: webhook_endpoint} =
      webhook_notification =
      WebhookNotifications.get_webhook_notification!(webhook_notification_id,
        includes: [:webhook_endpoint]
      )

    update_webhook_notification_attempt!(webhook_notification, attempt, next_retry_at)

    call_webhook_result_handler(
      webhook_result_handler,
      webhook_endpoint,
      webhook_notification,
      webhook_conversation
    )

    :ok
  end

  defp save_webhook_conversation!(
         %Response{} = response,
         %WebhookEndpoint{} = webhook_endpoint,
         %WebhookNotification{} = webhook_notification
       ) do
    {:ok, webhook_conversation} =
      response
      |> to_webhook_conversation_attrs(webhook_endpoint, webhook_notification)
      |> WebhookConversations.create_webhook_conversation()

    webhook_conversation
  end

  defp to_webhook_conversation_attrs(
         %Response{} = response,
         %WebhookEndpoint{id: webhook_endpoint_id},
         %WebhookNotification{id: webhook_notification_id}
       )
       when is_binary(webhook_endpoint_id) do
    status =
      if response.success?,
        do: WebhookConversation.statuses().succeeded,
        else: WebhookConversation.statuses().failed

    %{
      webhook_notification_id: webhook_notification_id,
      requested_at: response.requested_at,
      request_url: response.request_url,
      request_headers: response.request_headers,
      request_body: response.request_body,
      http_status: response.response_http_status,
      response_body: response.response_body,
      responded_at: response.responded_at,
      client_error_message: response.client_error_message,
      status: status
    }
  end

  defp set_webhook_notification_as_successful!(%WebhookNotification{} = webhook_notification) do
    {:ok, webhook_notification} =
      WebhookNotifications.update_webhook_notification(webhook_notification, %{
        attempt: webhook_notification.attempt + 1,
        succeeded_at: DateTime.utc_now(),
        next_retry_at: nil
      })

    webhook_notification
  end

  defp update_webhook_notification_attempt!(
         %WebhookNotification{} = webhook_notification,
         attempt,
         next_retry_at
       ) do
    WebhookNotifications.update_webhook_notification(webhook_notification, %{
      attempt: attempt,
      next_retry_at: next_retry_at
    })

    webhook_notification
  end

  defp call_webhook_result_handler(
         webhook_result_handler,
         %WebhookEndpoint{} = webhook_endpoint,
         %WebhookNotification{} = webhook_notification,
         %WebhookConversation{} = webhook_conversation
       ) do
    if webhook_result_handler do
      handler_module(webhook_result_handler).handle_failure(
        webhook_endpoint,
        webhook_notification,
        webhook_conversation
      )
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

  defp build_body(%WebhookNotification{} = webhook_notification) do
    webhook_notification.data
    |> Map.merge(%{webhook_endpoint_id: webhook_notification.webhook_endpoint_id})
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
