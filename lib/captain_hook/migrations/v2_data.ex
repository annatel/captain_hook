defmodule CaptainHook.Migrations.V2Data do
  def up do
    CaptainHook.list_webhook_endpoints(includes: [:enabled_notification_types])
    |> Enum.each(fn webhook_endpoint ->
      {:ok, _} =
        CaptainHook.WebhookEndpoints.Secrets.create_webhook_endpoint_secret(
          webhook_endpoint,
          webhook_endpoint.started_at
        )

      {:ok, _} =
        CaptainHook.update_webhook_endpoint(webhook_endpoint, %{
          enabled_notification_types: [%{name: "*"}]
        })
    end)
  end

  def down do
    :noop
  end
end
