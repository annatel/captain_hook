defmodule CaptainHookTest do
  use ExUnit.Case, async: false
  use CaptainHook.DataCase

  describe "failure_report_email_html_body/3" do
    test "when webhook_conversations_url is nil, do not link the webhook_endpoint_id" do
      webhook_endpoint = insert!(:webhook_endpoint)

      webhook_notification =
        insert!(:webhook_notification, webhook_endpoint_id: webhook_endpoint.id)

      webhook_convesation =
        insert!(:webhook_conversation,
          webhook_notification_id: webhook_notification.id,
          client_error_message: "client_error_message_text",
          request_body: "{}"
        )

      assert CaptainHook.failure_report_email_html_body(webhook_notification, webhook_convesation) ==
               """
               Hi,<br/>
               <br/>
               Here is a report about a webhook failure about the webhook endpoint #{webhook_endpoint.id}<br/>
               <br/>
               <b>Request url:</b> #{webhook_convesation.request_url}<br/>
               <b>HTTP status:</b> #{webhook_convesation.http_status}<br/><b>Client error message (if any):</b> #{webhook_convesation.client_error_message}
               <br/>
               <br/>
               <b>Response:</b> #{webhook_convesation.response_body}<br/>
               <b>Request:</b>
               <pre>
               #{webhook_convesation.request_body}
               </pre>
               <br/>
               <b>Please, fix the failure in order to unlock the flow of the reports.</b>
               <br/>
               """
    end

    test "when the webhook_conversations_url is not nil, links the webhook_endpoint_id" do
      webhook_endpoint = insert!(:webhook_endpoint)

      webhook_notification =
        insert!(:webhook_notification, webhook_endpoint_id: webhook_endpoint.id)

      webhook_convesation =
        insert!(:webhook_conversation,
          webhook_notification_id: webhook_notification.id,
          client_error_message: nil,
          request_body: "{}"
        )

      assert CaptainHook.failure_report_email_html_body(
               webhook_notification,
               webhook_convesation,
               "url"
             ) ==
               """
               Hi,<br/>
               <br/>
               Here is a report about a webhook failure about the webhook endpoint <a href='url'>#{webhook_endpoint.id}</a><br/>
               <br/>
               <b>Request url:</b> #{webhook_convesation.request_url}<br/>
               <b>HTTP status:</b> #{webhook_convesation.http_status}<br/>
               <br/>
               <br/>
               <b>Response:</b> #{webhook_convesation.response_body}<br/>
               <b>Request:</b>
               <pre>
               #{webhook_convesation.request_body}
               </pre>
               <br/>
               <b>Please, fix the failure in order to unlock the flow of the reports.</b>
               <br/>
               """
    end
  end
end
