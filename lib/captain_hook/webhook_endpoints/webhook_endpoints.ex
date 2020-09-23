defmodule CaptainHook.WebhookEndpoints do
  import Ecto.Query, only: [order_by: 2]

  alias AntlUtilsElixir.DateTime.Period
  alias CaptainHook.WebhookEndpoints.{WebhookEndpoint, WebhookEndpointQueryable}

  @spec list_webhook_endpoints(binary) :: [WebhookEndpoint.t()]
  def list_webhook_endpoints(webhook) do
    WebhookEndpointQueryable.queryable()
    |> WebhookEndpointQueryable.filter(webhook: webhook)
    |> order_by([:started_at])
    |> CaptainHook.repo().all()
  end

  @spec filter_webhook_endpoints([WebhookEndpoint.t()], atom, DateTime.t()) :: [
          WebhookEndpoint.t()
        ]
  def filter_webhook_endpoints(webhook_endpoints, status, %DateTime{} = datetime) do
    webhook_endpoints
    |> Period.filter_by_status(status, datetime, :started_at, :ended_at)
  end

  @spec get_webhook_endpoint(binary, binary) :: WebhookEndpoint.t()
  def get_webhook_endpoint(webhook, id) when is_binary(webhook) and is_binary(id) do
    WebhookEndpointQueryable.queryable()
    |> WebhookEndpointQueryable.filter(webhook: webhook, id: id)
    |> CaptainHook.repo().one()
  end

  @spec get_webhook_endpoint!(binary, binary) :: WebhookEndpoint.t()
  def get_webhook_endpoint!(webhook, id) when is_binary(webhook) and is_binary(id) do
    WebhookEndpointQueryable.queryable()
    |> WebhookEndpointQueryable.filter(webhook: webhook, id: id)
    |> CaptainHook.repo().one!()
  end

  @spec create_webhook_endpoint(binary, map()) :: WebhookEndpoint.t()
  def create_webhook_endpoint(webhook, attrs) when is_map(attrs) do
    attrs = attrs |> Map.put(:webhook, webhook)

    %WebhookEndpoint{}
    |> WebhookEndpoint.create_changeset(attrs)
    |> CaptainHook.repo().insert()
  end

  @spec update_webhook_endpoint(WebhookEndpoint.t(), map()) :: WebhookEndpoint.t()
  def update_webhook_endpoint(%WebhookEndpoint{id: _id} = webhook_endpoint, attrs)
      when is_map(attrs) do
    webhook_endpoint
    |> WebhookEndpoint.update_changeset(attrs)
    |> CaptainHook.repo().update()
  end

  @spec delete_webhook_endpoint(WebhookEndpoint.t(), DateTime.t()) :: WebhookEndpoint.t()
  def delete_webhook_endpoint(
        %WebhookEndpoint{id: _id, ended_at: nil} = webhook_endpoint,
        %DateTime{} = ended_at \\ DateTime.utc_now()
      ) do
    webhook_endpoint
    |> WebhookEndpoint.remove_changeset(%{ended_at: ended_at})
    |> CaptainHook.repo().update()
  end
end
