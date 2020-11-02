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

  @spec get_webhook_endpoint(binary, boolean) :: WebhookEndpoint.t()
  def get_webhook_endpoint(id, with_secret? \\ false) when is_binary(id) do
    query =
      WebhookEndpointQueryable.queryable()
      |> WebhookEndpointQueryable.filter(id: id)

    query = if with_secret?, do: query |> WebhookEndpointQueryable.with_secret(), else: query

    result =
      query
      |> CaptainHook.repo().one()

    if with_secret? do
      [webhook_endpoint, secret] = result
      webhook_endpoint |> Map.merge(secret)
    else
      result
    end
  end

  @spec get_webhook_endpoint!(binary) :: WebhookEndpoint.t()
  def get_webhook_endpoint!(id) when is_binary(id) do
    WebhookEndpointQueryable.queryable()
    |> WebhookEndpointQueryable.filter(id: id)
    |> CaptainHook.repo().one!()
  end

  @spec create_webhook_endpoint(map()) :: WebhookEndpoint.t()
  def create_webhook_endpoint(attrs) when is_map(attrs) do
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
