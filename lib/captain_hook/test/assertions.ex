defmodule CaptainHook.Test.Assertions do
  import ExUnit.Assertions

  alias CaptainHook.WebhookEndpoints
  alias CaptainHook.WebhookNotifications
  alias CaptainHook.WebhookConversations

  @doc """
  Asserts an event is created

  It can be used as below:

  # Examples:

      assert_webhook_conversation_created()
      assert_webhook_conversation_created(%{webhook_notification_id: "id")
  """
  def assert_webhook_conversation_created(attrs \\ %{})

  def assert_webhook_conversation_created(%{} = attrs),
    do: assert_webhook_conversation_created(1, attrs)

  def assert_webhook_conversation_created(expected_count) when is_integer(expected_count),
    do: assert_webhook_conversation_created(expected_count, %{})

  def assert_webhook_conversation_created(expected_count, attrs)
      when is_integer(expected_count) do
    webhook_conversations =
      WebhookConversations.list_webhook_conversations(filters: attrs |> Enum.to_list())

    count = length(webhook_conversations)

    assert count == expected_count, message("webhook_conversation", attrs, expected_count, count)
  end

  @doc """
  Asserts the notifications has just been created

  It can be used as below:

  # Examples:

      assert_webhook_notifications_created("id", "object")
      assert_webhook_notifications_created("id", "object", %{"param" => "b"})
      assert_webhook_notifications_created("id", "object", [endpoint_id,...])
      assert_webhook_notifications_created("id", "object",  %{"param" => "b"}, [endpoint_id,...])
  """
  def assert_webhook_notifications_created(resource_id, resource_object)
      when is_binary(resource_id) and is_binary(resource_object) do
    webhook_notifications =
      WebhookNotifications.list_webhook_notifications(
        filters: [resource_id: resource_id, resource_object: resource_object]
      )

    assert length(webhook_notifications) != 0, "Expected a webhook_notification, got none"
  end

  def assert_webhook_notifications_created(
        resource_id,
        resource_object,
        data
      )
      when is_binary(resource_id) and is_binary(resource_object) and is_map(data) do
    webhook_notifications =
      WebhookNotifications.list_webhook_notifications(
        filters: [resource_id: resource_id, resource_object: resource_object]
      )

    assert length(webhook_notifications) != 0, "Expected a webhook_notification, got none"
    assert_notifications_created_with_data(webhook_notifications, data)
  end

  def assert_webhook_notifications_created(
        resource_id,
        resource_object,
        webhook_endpoint_ids
      )
      when is_binary(resource_id) and is_binary(resource_object) and is_list(webhook_endpoint_ids) do
    webhook_notifications =
      WebhookNotifications.list_webhook_notifications(
        filters: [resource_id: resource_id, resource_object: resource_object]
      )

    assert length(webhook_notifications) != 0, "Expected a webhook_notification, got none"

    assert_webhook_notifications_created_for_endpoints(
      webhook_notifications,
      webhook_endpoint_ids
    )
  end

  def assert_webhook_notifications_created(
        resource_id,
        resource_object,
        webhook_endpoint_ids,
        data
      )
      when is_binary(resource_id) and is_binary(resource_object) and is_list(webhook_endpoint_ids) and
             is_map(data) do
    webhook_notifications =
      WebhookNotifications.list_webhook_notifications(
        filters: [resource_id: resource_id, resource_object: resource_object]
      )

    assert length(webhook_notifications) != 0, "Expected a webhook_notification, got none"

    assert_notifications_created_with_data(webhook_notifications, data)

    assert_webhook_notifications_created_for_endpoints(
      webhook_notifications,
      webhook_endpoint_ids
    )
  end

  defp assert_notifications_created_with_data(webhook_notifications, data)
       when is_list(webhook_notifications) and is_map(data) do
    Enum.each(webhook_notifications, fn webhook_notification ->
      assert subset?(data, webhook_notification.data),
             """
             Expected a webhook_notification with data:
             #{inspect(data, pretty: true)}
             Found webhook_notification with data: #{inspect(webhook_notification.data, pretty: true)}
             """
    end)
  end

  defp assert_webhook_notifications_created_for_endpoints(
         webhook_notifications,
         expected_webhook_endpoint_ids
       )
       when is_list(webhook_notifications) and is_list(expected_webhook_endpoint_ids) do
    webhook_endpoint_ids = webhook_notifications |> Enum.map(& &1.webhook_endpoint_id)

    Enum.each(expected_webhook_endpoint_ids, fn expected_webhook_endpoint_id ->
      assert expected_webhook_endpoint_id in webhook_endpoint_ids, """
      Expected a webhook_notification for the webhook_endpoint_id #{expected_webhook_endpoint_id}, got none.
      """
    end)
  end

  @doc """
  Asserts the endpoint has just been created

  It can be used as below:

  # Examples:

      assert_webhook_endpoint_created("owner_id", %{attr_1: "a"})
      assert_webhook_endpoint_created("owner_id", %{attr_1: "a", enabled_notification_types: ["*"]})
  """

  def assert_webhook_endpoints_created(owner_id, attrs \\ %{})
      when is_binary(owner_id) and is_map(attrs) do
    owner_id_field = elem(CaptainHook.owner_id_field(:schema), 0)

    webhook_endpoints =
      WebhookEndpoints.list_webhook_endpoints(
        filters:
          Keyword.new([{owner_id_field, owner_id}]) ++
            (attrs |> Map.delete(:enabled_notification_types) |> Enum.to_list()),
        includes: [:enabled_notification_types]
      )

    assert length(webhook_endpoints) > 0,
           "Expected a webhook endpoint with the attributes #{inspect(attrs)}, got none"

    case attrs do
      %{enabled_notification_types: expected_enabled_notification_types} ->
        Enum.each(webhook_endpoints, fn webhook_endpoint ->
          enabled_notification_type_names =
            webhook_endpoint.enabled_notification_types |> Enum.map(& &1.name)

          assert subset?(
                   expected_enabled_notification_types,
                   enabled_notification_type_names
                 ),
                 """
                   Expected enabled_notification_types #{inspect(expected_enabled_notification_types, pretty: true)},
                   got: #{inspect(enabled_notification_type_names, pretty: true)}
                 """
        end)

      _ ->
        :noop
    end
  end

  defp subset?(a, b) do
    MapSet.subset?(a |> MapSet.new(), b |> MapSet.new())
  end

  defp message(resource_name, %{} = attrs, expected_count, count) do
    if Enum.empty?(attrs),
      do:
        "Expected #{expected_count} #{maybe_pluralized_item(resource_name, expected_count)}, got #{count}",
      else:
        "Expected #{expected_count} #{maybe_pluralized_item(resource_name, expected_count)} with attributes #{inspect(attrs)}, got #{count}"
  end

  defp maybe_pluralized_item(resource_name, count) when count > 1, do: resource_name <> "s"
  defp maybe_pluralized_item(resource_name, _), do: resource_name
end
