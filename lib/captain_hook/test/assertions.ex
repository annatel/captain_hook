defmodule CaptainHook.Test.Assertions do
  import ExUnit.Assertions

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
    %{total: total, data: _} =
      CaptainHook.list_webhook_notifications(
        filters: [resource_id: resource_id, resource_object: resource_object]
      )

    assert total != 0, "Expected a webhook_notification, got none"
  end

  def assert_webhook_notifications_created(
        resource_id,
        resource_object,
        data
      )
      when is_binary(resource_id) and is_binary(resource_object) and is_map(data) do
    %{total: total, data: webhook_notifications} =
      CaptainHook.list_webhook_notifications(
        filters: [resource_id: resource_id, resource_object: resource_object]
      )

    assert total != 0, "Expected a webhook_notification, got none"
    assert_notifications_created_with_data(webhook_notifications, data)
  end

  def assert_webhook_notifications_created(
        resource_id,
        resource_object,
        webhook_endpoint_ids
      )
      when is_binary(resource_id) and is_binary(resource_object) and is_list(webhook_endpoint_ids) do
    %{total: total, data: webhook_notifications} =
      CaptainHook.list_webhook_notifications(
        filters: [resource_id: resource_id, resource_object: resource_object]
      )

    assert total != 0, "Expected a webhook_notification, got none"

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
    %{total: total, data: webhook_notifications} =
      CaptainHook.list_webhook_notifications(
        filters: [resource_id: resource_id, resource_object: resource_object]
      )

    assert total != 0, "Expected a webhook_notification, got none"

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
             Found webhook_notification with data: #{
               inspect(webhook_notification.data, pretty: true)
             }
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

      assert_webhook_endpoint_created("topic", %{attr_1: "a"})
      assert_webhook_endpoint_created("topic", %{attr_1: "a", enabled_notification_types: ["*"]})
  """

  def assert_webhook_endpoints_created(topic, attrs \\ %{})
      when is_binary(topic) and is_map(attrs) do
    %{total: total, data: webhook_endpoints} =
      CaptainHook.list_webhook_endpoints(
        filters:
          [topic: topic] ++ (attrs |> Map.delete(:enabled_notification_types) |> Enum.to_list()),
        includes: [:enabled_notification_types]
      )

    assert total > 0,
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
                   Expected enabled_notification_types #{
                   inspect(expected_enabled_notification_types, pretty: true)
                 },
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
end
