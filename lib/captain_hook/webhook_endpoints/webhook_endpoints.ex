defmodule CaptainHook.WebhookEndpoints do
  import Ecto.Query, only: [order_by: 2]

  alias Ecto.Multi

  alias CaptainHook.WebhookEndpoints.{WebhookEndpoint, WebhookEndpointQueryable}
  alias CaptainHook.WebhookSecrets

  @spec list_webhook_endpoints(keyword) :: [WebhookEndpoint.t()]
  def list_webhook_endpoints(opts \\ []) do
    opts
    |> webhook_endpoint_queryable()
    |> order_by(asc: :started_at)
    |> CaptainHook.repo().all()
  end

  @spec get_webhook_endpoint(binary, boolean) :: WebhookEndpoint.t()
  def get_webhook_endpoint(id, include_secret? \\ false) when is_binary(id) do
    query =
      WebhookEndpointQueryable.queryable()
      |> WebhookEndpointQueryable.filter(id: id)

    query =
      if include_secret?, do: query |> WebhookEndpointQueryable.include_secret(), else: query

    query
    |> CaptainHook.repo().one()
  end

  @spec get_webhook_endpoint!(binary) :: WebhookEndpoint.t()
  def get_webhook_endpoint!(id) when is_binary(id) do
    WebhookEndpointQueryable.queryable()
    |> WebhookEndpointQueryable.filter(id: id)
    |> CaptainHook.repo().one!()
  end

  @spec create_webhook_endpoint(map()) :: WebhookEndpoint.t()
  def create_webhook_endpoint(attrs) when is_map(attrs) do
    Multi.new()
    |> Multi.insert(
      :webhook_endpoint,
      %WebhookEndpoint{} |> WebhookEndpoint.create_changeset(attrs)
    )
    |> Multi.run(:create_webhook_secret, fn _, %{webhook_endpoint: webhook_endpoint} ->
      WebhookSecrets.create_webhook_secret(webhook_endpoint, webhook_endpoint.started_at)
    end)
    |> CaptainHook.repo().transaction()
    |> case do
      {:ok, %{webhook_endpoint: webhook_endpoint}} -> {:ok, webhook_endpoint}
      {:error, _, failed_value, _} -> {:error, failed_value}
    end
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
        %WebhookEndpoint{ended_at: nil} = webhook_endpoint,
        %DateTime{} = ended_at
      ) do
    webhook_secrets = WebhookSecrets.list_webhook_secrets(webhook_endpoint)

    Multi.new()
    |> Multi.update(
      :webhook_endpoint,
      webhook_endpoint |> WebhookEndpoint.remove_changeset(%{ended_at: ended_at})
    )
    |> Multi.merge(fn _ ->
      webhook_secrets
      |> Enum.reduce(Multi.new(), fn webhook_secret, acc ->
        acc
        |> Multi.run(:"remove_webhook_secret_#{webhook_secret.id}", fn _repo, %{} ->
          WebhookSecrets.remove_webhook_secret(webhook_secret, ended_at)
        end)
      end)
    end)
    |> CaptainHook.repo().transaction()
    |> case do
      {:ok, %{webhook_endpoint: webhook_endpoint}} -> {:ok, webhook_endpoint}
      {:error, _, failed_value, _} -> {:error, failed_value}
    end
  end

  @spec webhook_endpoint_queryable(keyword) :: Ecto.Queryable.t()
  def webhook_endpoint_queryable(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])

    WebhookEndpointQueryable.queryable()
    |> WebhookEndpointQueryable.filter(filters)
  end
end
