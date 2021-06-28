defmodule CaptainHook.Test.AssertionsTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase
  import CaptainHook.Test.Assertions

  describe "assert_webhook_notifications_created/2" do
    test "when the notification is found" do
      %{resource_id: resource_id, resource_object: resource_object} =
        insert!(:webhook_notification)

      assert_webhook_notifications_created(resource_id, resource_object)
    end

    test "when the notification is not found" do
      message =
        %ExUnit.AssertionError{
          message: "Expected a webhook_notification, got none"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_notifications_created("resource_id", "resource_object")
      end
    end
  end

  describe "assert_webhook_notifications_created/3 - with data" do
    test "when the notification is found" do
      data = %{"a" => "A"}

      %{resource_id: resource_id, resource_object: resource_object} =
        insert!(:webhook_notification, data: data)

      assert_webhook_notifications_created(resource_id, resource_object, data)
    end

    test "when no notification is found for the resource_id and the resource_object" do
      message =
        %ExUnit.AssertionError{
          message: "Expected a webhook_notification, got none"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_notifications_created(
          "resource_id",
          "resource_object",
          %{"a" => "B"}
        )
      end
    end

    test "when the notifications found doesn't contain the expected data" do
      %{resource_id: resource_id, resource_object: resource_object} =
        insert!(:webhook_notification, data: %{"a" => "A"})

      message =
        %ExUnit.AssertionError{
          message: """
          Expected a webhook_notification with data:
          %{"a" => "B"}
          Found webhook_notification with data: %{"a" => "A"}
          """
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_notifications_created(
          resource_id,
          resource_object,
          %{"a" => "B"}
        )
      end
    end
  end

  describe "assert_webhook_notifications_created/3 - with webhook_endpoint_ids" do
    test "when the notification is found" do
      %{
        webhook_endpoint_id: webhook_endpoint_id,
        resource_id: resource_id,
        resource_object: resource_object
      } = insert!(:webhook_notification)

      assert_webhook_notifications_created(resource_id, resource_object, [webhook_endpoint_id])
    end

    test "when no notification is found for the resource_id and the resource_object" do
      message =
        %ExUnit.AssertionError{
          message: "Expected a webhook_notification, got none"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_notifications_created(
          "resource_id",
          "resource_object",
          [shortcode_uuid("we")]
        )
      end
    end

    test "when the notifications are not created to the expected webhook_enpoint_ids" do
      webhook_endpoint_id = shortcode_uuid("we")

      %{
        resource_id: resource_id,
        resource_object: resource_object
      } = insert!(:webhook_notification)

      message =
        %ExUnit.AssertionError{
          message: """
          Expected a webhook_notification for the webhook_endpoint_id #{webhook_endpoint_id}, got none.
          """
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_notifications_created(
          resource_id,
          resource_object,
          [webhook_endpoint_id]
        )
      end
    end
  end

  describe "assert_webhook_notifications_created/4 - with webhook_endpoint_ids and data" do
    test "when the notification is found" do
      data = %{"a" => "A"}

      %{
        webhook_endpoint_id: webhook_endpoint_id,
        resource_id: resource_id,
        resource_object: resource_object
      } = insert!(:webhook_notification, data: data)

      assert_webhook_notifications_created(
        resource_id,
        resource_object,
        [webhook_endpoint_id],
        data
      )
    end

    test "when no notification is found for the resource_id and the resource_object" do
      message =
        %ExUnit.AssertionError{
          message: "Expected a webhook_notification, got none"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_notifications_created(
          "resource_id",
          "resource_object",
          [shortcode_uuid("we")],
          %{"a" => "A"}
        )
      end
    end

    test "when the notifications are not created to the expected webhook_enpoint_ids" do
      data = %{"a" => "A"}
      webhook_endpoint_id = shortcode_uuid("we")

      %{
        resource_id: resource_id,
        resource_object: resource_object
      } = insert!(:webhook_notification, data: data)

      message =
        %ExUnit.AssertionError{
          message: """
          Expected a webhook_notification for the webhook_endpoint_id #{webhook_endpoint_id}, got none.
          """
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_notifications_created(
          resource_id,
          resource_object,
          [webhook_endpoint_id],
          %{"a" => "A"}
        )
      end
    end

    test "when the notifications are not created with the expected data" do
      data = %{"a" => "A"}

      %{
        resource_id: resource_id,
        resource_object: resource_object
      } = insert!(:webhook_notification, data: data)

      message =
        %ExUnit.AssertionError{
          message: """
          Expected a webhook_notification with data:
          %{"a" => "B"}
          Found webhook_notification with data: %{"a" => "A"}
          """
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_notifications_created(
          resource_id,
          resource_object,
          [shortcode_uuid("we")],
          %{"a" => "B"}
        )
      end
    end
  end

  describe "assert_webhook_endpoints_created/2" do
    test "when the webhoook_endpoint is created" do
      %{topic: topic} = insert!(:webhook_endpoint)
      assert_webhook_endpoints_created(topic, %{enabled_notification_types: ["*"]})
    end

    test "when no webhoook_endpoint exist for the topic" do
      message =
        %ExUnit.AssertionError{
          message: "Expected a webhook endpoint with the attributes %{}, got none"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_endpoints_created("topic")
      end
    end

    test "when attributes don't match" do
      %{topic: topic} = insert!(:webhook_endpoint)

      message =
        %ExUnit.AssertionError{
          message: "Expected a webhook endpoint with the attributes %{url: \"url\"}, got none"
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_endpoints_created(topic, %{
          url: "url"
        })
      end
    end

    test "when some expected enabled_notification_types are missing" do
      %{topic: topic} = insert!(:webhook_endpoint)

      message =
        %ExUnit.AssertionError{
          message: """
            Expected enabled_notification_types [\"url\"],
            got: [\"*\"]
          """
        }
        |> ExUnit.AssertionError.message()

      assert_raise ExUnit.AssertionError, message, fn ->
        assert_webhook_endpoints_created(topic, %{
          enabled_notification_types: ["url"]
        })
      end
    end
  end
end
