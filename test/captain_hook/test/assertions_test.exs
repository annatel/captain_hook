defmodule CaptainHook.Test.AssertionsTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  import CaptainHook.Test.Assertions

  @notification_pattern_wildcard Application.get_env(
                                   :captain_hook,
                                   :notification_pattern_wildcard
                                 )
  describe "assert_webhook_conversation_created/0" do
    test "when the webhook_conversation is found" do
      webhook_notification = insert!(:webhook_notification)

      insert!(:webhook_conversation, webhook_notification_id: webhook_notification.id)

      assert_webhook_conversation_created()
    end

    test "count option" do
      webhook_notification = insert!(:webhook_notification)
      insert!(:webhook_conversation, webhook_notification_id: webhook_notification.id)

      message =
        %ExUnit.AssertionError{
          message: "Expected 2 webhook_conversations, got 1"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_conversation_created(2)
      end
    end

    test "when the webhook_conversation is not found" do
      message =
        %ExUnit.AssertionError{message: "Expected 1 webhook_conversation, got 0"}
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_conversation_created()
      end
    end
  end

  describe "assert_webhook_conversation_created/1" do
    test "when the webhook_conversation is found" do
      webhook_notification = insert!(:webhook_notification)

      %{request_url: request_url} =
        insert!(:webhook_conversation, webhook_notification_id: webhook_notification.id)

      insert!(:webhook_conversation, webhook_notification_id: webhook_notification.id)

      assert_webhook_conversation_created(%{request_url: request_url})
    end

    test "when the webhook_conversation is not found" do
      message =
        %ExUnit.AssertionError{
          message:
            "Expected 1 webhook_conversation with attributes %{webhook_notification_id: \"webhook_notification_id\"}, got 0"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_conversation_created(%{webhook_notification_id: "webhook_notification_id"})
      end
    end

    test "count option" do
      webhook_notification = insert!(:webhook_notification)

      insert!(:webhook_conversation, webhook_notification_id: webhook_notification.id)
      insert!(:webhook_conversation, webhook_notification_id: webhook_notification.id)

      message =
        %ExUnit.AssertionError{
          message:
            "Expected 1 webhook_conversation with attributes %{webhook_notification_id: \"#{webhook_notification.id}\"}, got 2"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_conversation_created(1, %{webhook_notification_id: webhook_notification.id})
      end
    end
  end

  describe "assert_webhook_notification_created/0" do
    test "when the webhook_notification is found" do
      insert!(:webhook_notification)
      assert_webhook_notification_created()
    end

    test "count option" do
      insert!(:webhook_notification)

      message =
        %ExUnit.AssertionError{
          message: "Expected 2 webhook_notifications, got 1"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_notification_created(2)
      end
    end

    test "when the webhook_notification is not found" do
      message =
        %ExUnit.AssertionError{message: "Expected 1 webhook_notification, got 0"}
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_notification_created()
      end
    end
  end

  describe "assert_webhook_notification_created/1" do
    test "when the webhook_conversation is found" do
      %{resource_id: resource_id} = insert!(:webhook_notification)
      insert!(:webhook_notification)

      assert_webhook_notification_created(%{resource_id: resource_id})
    end

    test "when the webhook_notification is not found" do
      message =
        %ExUnit.AssertionError{
          message:
            "Expected 1 webhook_notification with attributes %{resource_id: \"resource_id\"}, got 0"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_notification_created(%{resource_id: "resource_id"})
      end
    end

    test "count option" do
      %{resource_id: resource_id} = insert!(:webhook_notification)

      insert!(:webhook_notification, resource_id: resource_id)

      message =
        %ExUnit.AssertionError{
          message:
            "Expected 1 webhook_notification with attributes %{resource_id: \"#{resource_id}\"}, got 2"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_notification_created(1, %{resource_id: resource_id})
      end
    end

    test "when data is specified" do
      %{resource_id: resource_id, data: data} = insert!(:webhook_notification)
      insert!(:webhook_notification)

      assert_webhook_notification_created(%{
        resource_id: resource_id,
        data: data |> Recase.Enumerable.stringify_keys()
      })
    end

    test "when data is specified but not match" do
      %{data: %{key: "value"}} = insert!(:webhook_notification, data: %{key: "value"})

      message =
        %ExUnit.AssertionError{
          message:
            "Expected 1 webhook_notification with attributes %{data: %{\"key\" => \"wrong_value\"}}, got 0"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_notification_created(%{data: %{"key" => "wrong_value"}})
      end
    end

    test "with data, count option" do
      %{data: %{key: "value"}} = insert!(:webhook_notification, data: %{key: "value"})
      insert!(:webhook_notification, data: %{key: "value"})

      message =
        %ExUnit.AssertionError{
          message:
            "Expected 1 webhook_notification with attributes %{data: %{\"key\" => \"value\"}}, got 2"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_notification_created(1, %{data: %{"key" => "value"}})
      end
    end
  end

  describe "assert_webhook_endpoint_created/0" do
    test "when the webhook_endpoint is found" do
      insert!(:webhook_endpoint)
      assert_webhook_endpoint_created()
    end

    test "count option" do
      insert!(:webhook_endpoint)

      message =
        %ExUnit.AssertionError{
          message: "Expected 2 webhook_endpoints, got 1"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_endpoint_created(2)
      end
    end

    test "when the webhook_endpoint is not found" do
      message =
        %ExUnit.AssertionError{message: "Expected 1 webhook_endpoint, got 0"}
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_endpoint_created()
      end
    end
  end

  describe "assert_webhook_endpoint_created/1" do
    test "when the webhook_endpoint is found" do
      %{url: url} = insert!(:webhook_endpoint)
      insert!(:webhook_endpoint)

      assert_webhook_endpoint_created(%{url: url})
    end

    test "when the webhook_endpoint is not found" do
      message =
        %ExUnit.AssertionError{
          message: "Expected 1 webhook_endpoint with attributes %{url: \"url\"}, got 0"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_endpoint_created(%{url: "url"})
      end
    end

    test "count option" do
      %{url: url} = insert!(:webhook_endpoint)

      insert!(:webhook_endpoint, url: url)

      message =
        %ExUnit.AssertionError{
          message: "Expected 1 webhook_endpoint with attributes %{url: \"#{url}\"}, got 2"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_endpoint_created(1, %{url: url})
      end
    end

    test "when enabled_notification_patterns is specified" do
      %{url: url, enabled_notification_patterns: enabled_notification_patterns} =
        insert!(:webhook_endpoint)

      insert!(:webhook_endpoint)

      assert_webhook_endpoint_created(%{
        url: url,
        enabled_notification_patterns:
          enabled_notification_patterns
          |> Enum.map(&Map.from_struct/1)
          |> Recase.Enumerable.stringify_keys()
      })
    end

    test "when enabled_notification_pattern is specified but not match" do
      insert!(:webhook_endpoint,
        enabled_notification_patterns: [
          build(:enabled_notification_pattern, pattern: @notification_pattern_wildcard)
        ]
      )

      message =
        %ExUnit.AssertionError{
          message:
            "Expected 1 webhook_endpoint with attributes %{enabled_notification_patterns: [%{\"pattern\" => \"wrong_value\"}]}, got 0"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_endpoint_created(%{
          enabled_notification_patterns: [%{"pattern" => "wrong_value"}]
        })
      end
    end

    test "with data, count option" do
      insert!(:webhook_endpoint,
        enabled_notification_patterns: [
          build(:enabled_notification_pattern, pattern: @notification_pattern_wildcard)
        ]
      )

      insert!(:webhook_endpoint,
        enabled_notification_patterns: [
          build(:enabled_notification_pattern, pattern: @notification_pattern_wildcard)
        ]
      )

      message =
        %ExUnit.AssertionError{
          message:
            "Expected 1 webhook_endpoint with attributes %{enabled_notification_patterns: [%{\"pattern\" => \"#{@notification_pattern_wildcard}\"}]}, got 2"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_endpoint_created(1, %{
          enabled_notification_patterns: [%{"pattern" => @notification_pattern_wildcard}]
        })
      end
    end
  end
end
