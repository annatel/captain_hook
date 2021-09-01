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
      assert_webhook_conversation_created(1)
      assert_webhook_conversation_created(%{webhook_notification_id: "id")
      assert_webhook_conversation_created(2, %{webhook_notification_id: "id")
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

      assert_webhook_notification_created()
      assert_webhook_notification_created(1)
      assert_webhook_notification_created(%{webhook_endpoint_id: "id")
      assert_webhook_notification_created(2, %{resource_id: "id", "resource_object": "resource_object")
  """
  def assert_webhook_notification_created(attrs \\ %{})

  def assert_webhook_notification_created(%{} = attrs),
    do: assert_webhook_notification_created(1, attrs)

  def assert_webhook_notification_created(expected_count) when is_integer(expected_count),
    do: assert_webhook_notification_created(expected_count, %{})

  def assert_webhook_notification_created(expected_count, %{data: data} = attrs)
      when is_integer(expected_count) do
    webhook_notifications =
      WebhookNotifications.list_webhook_notifications(
        filters: attrs |> Map.delete(:data) |> Enum.to_list()
      )

    count =
      webhook_notifications
      |> Enum.filter(fn webhook_notification -> subset?(data, webhook_notification.data) end)
      |> length()

    assert count == expected_count, message("webhook_notification", attrs, expected_count, count)
  end

  def assert_webhook_notification_created(expected_count, attrs)
      when is_integer(expected_count) do
    webhook_notifications =
      WebhookNotifications.list_webhook_notifications(filters: attrs |> Enum.to_list())

    count = length(webhook_notifications)

    assert count == expected_count, message("webhook_notification", attrs, expected_count, count)
  end

  @doc """
  Asserts the endpoint has just been created

  It can be used as below:

  # Examples:

      assert_webhook_endpoint_created()
      assert_webhook_endpoint_created(1)
      assert_webhook_endpoint_created(%{onwer_id: "id")
      assert_webhook_endpoint_created(2, %{onwer_id: "id")
  """

  def assert_webhook_endpoint_created(attrs \\ %{})

  def assert_webhook_endpoint_created(%{} = attrs),
    do: assert_webhook_endpoint_created(1, attrs)

  def assert_webhook_endpoint_created(expected_count) when is_integer(expected_count),
    do: assert_webhook_endpoint_created(expected_count, %{})

  def assert_webhook_endpoint_created(
        expected_count,
        %{enabled_notification_patterns: enabled_notification_patterns} = attrs
      )
      when is_integer(expected_count) do
    webhook_endpoints =
      WebhookEndpoints.list_webhook_endpoints(
        filters: attrs |> Map.delete(:enabled_notification_patterns) |> Enum.to_list()
      )

    count =
      webhook_endpoints
      |> Enum.filter(fn webhook_endpoint ->
        webhook_endpoint_enabled_notification_patterns =
          webhook_endpoint.enabled_notification_patterns
          |> Enum.map(&Map.from_struct/1)
          |> Recase.Enumerable.stringify_keys()

        subset?(enabled_notification_patterns, webhook_endpoint_enabled_notification_patterns)
      end)
      |> length()

    assert count == expected_count, message("webhook_endpoint", attrs, expected_count, count)
  end

  def assert_webhook_endpoint_created(expected_count, attrs)
      when is_integer(expected_count) do
    webhook_endpoints = WebhookEndpoints.list_webhook_endpoints(filters: attrs |> Enum.to_list())

    count = length(webhook_endpoints)

    assert count == expected_count, message("webhook_endpoint", attrs, expected_count, count)
  end

  defp subset?(list_a, list_b) when is_list(list_a) and is_list(list_b) do
    list_a
    |> Enum.all?(fn a_item ->
      list_b |> Enum.any?(fn b_item -> subset?(a_item, b_item) end)
    end)
  end

  defp subset?(a, b) do
    MapSet.subset?(a |> MapSet.new(), b |> MapSet.new())
  end

  defp message(resource_name, %{} = attrs, expected_count, count) do
    if Enum.empty?(attrs),
      do:
        "Expected #{expected_count} #{maybe_pluralized_item(resource_name, expected_count)}, got #{count}",
      else:
        "Expected #{expected_count} #{maybe_pluralized_item(resource_name, expected_count)} with attributes #{inspect(attrs, pretty: true)}, got #{count}"
  end

  defp maybe_pluralized_item(resource_name, count) when count > 1, do: resource_name <> "s"
  defp maybe_pluralized_item(resource_name, _), do: resource_name
end
