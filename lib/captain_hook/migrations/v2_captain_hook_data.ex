defmodule CaptainHook.Migrations.V2.CaptainHook.Data do
  def up do
    CaptainHook.list_webhook_endpoints(includes: [:enabled_notification_types, :secret])
    |> Enum.each(fn webhook_endpoint ->
      unless webhook_endpoint.secret do
        {:ok, _} =
          CaptainHook.WebhookEndpoints.Secrets.create_webhook_endpoint_secret(
            webhook_endpoint,
            webhook_endpoint.started_at
          )
      end

      if length(webhook_endpoint.enabled_notification_types) == 0 do
        {:ok, _} =
          CaptainHook.update_webhook_endpoint(webhook_endpoint, %{
            enabled_notification_types: [%{name: "*"}]
          })
      end
    end)
  end

  def down do
    :noop
  end
end
