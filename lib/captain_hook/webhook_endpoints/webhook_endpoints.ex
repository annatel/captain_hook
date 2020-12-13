defmodule CaptainHook.WebhookEndpoints do
  import Ecto.Query, only: [order_by: 2]

  alias Ecto.Multi

  alias CaptainHook.WebhookEndpoints.{WebhookEndpoint, WebhookEndpointQueryable}
  alias CaptainHook.WebhookEndpoints.Secrets

  @spec list_webhook_endpoints(keyword) :: [WebhookEndpoint.t()]
  def list_webhook_endpoints(opts \\ []) do
    opts
    |> webhook_endpoint_queryable()
    |> order_by(asc: :started_at)
    |> CaptainHook.repo().all()
  end

  @spec get_webhook_endpoint(binary, keyword) :: WebhookEndpoint.t()
  def get_webhook_endpoint(id, opts \\ []) when is_binary(id) do
    opts
    |> Keyword.put(:filters, id: id)
    |> webhook_endpoint_queryable()
    |> CaptainHook.repo().one()
  end

  @spec get_webhook_endpoint!(binary, keyword) :: WebhookEndpoint.t()
  def get_webhook_endpoint!(id, opts \\ []) when is_binary(id) do
    opts
    |> Keyword.put(:filters, id: id)
    |> webhook_endpoint_queryable()
    |> CaptainHook.repo().one!()
  end

  @spec create_webhook_endpoint(map()) :: WebhookEndpoint.t()
  def create_webhook_endpoint(attrs) when is_map(attrs) do
    Multi.new()
    |> Multi.insert(
      :webhook_endpoint,
      %WebhookEndpoint{} |> WebhookEndpoint.create_changeset(attrs)
    )
    |> Multi.run(:create_webhook_endpoint_secret, fn _, %{webhook_endpoint: webhook_endpoint} ->
      Secrets.create_webhook_endpoint_secret(webhook_endpoint, webhook_endpoint.started_at)
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
    webhook_secrets = Secrets.list_webhook_endpoint_secrets(webhook_endpoint)

    Multi.new()
    |> Multi.update(
      :webhook_endpoint,
      webhook_endpoint |> WebhookEndpoint.remove_changeset(%{ended_at: ended_at})
    )
    |> Multi.merge(fn _ ->
      webhook_secrets
      |> Enum.reduce(Multi.new(), fn webhook_secret, acc ->
        acc
        |> Multi.run(:"remove_webhook_endpoint_secret_#{webhook_secret.id}", fn _repo, %{} ->
          Secrets.remove_webhook_endpoint_secret(webhook_secret, ended_at)
        end)
      end)
    end)
    |> CaptainHook.repo().transaction()
    |> case do
      {:ok, %{webhook_endpoint: webhook_endpoint}} -> {:ok, webhook_endpoint}
      {:error, _, failed_value, _} -> {:error, failed_value}
    end
  end

  @spec enable_notification_type(WebhookEndpoint.t(), binary | [binary]) :: WebhookEndpoint.t()
  def enable_notification_type(%WebhookEndpoint{} = webhook_endpoint, notification_type) do
    %{enabled_notification_types: enabled_notification_types} =
      webhook_endpoint |> CaptainHook.repo().preload(:enabled_notification_types)

    enabled_notification_types =
      notification_type
      |> List.wrap()
      |> Enum.map(&%{name: &1})
      |> Enum.concat(enabled_notification_types)
      |> Enum.reverse()
      |> Enum.uniq_by(fn %{name: name} -> name end)

    webhook_endpoint
    |> update_webhook_endpoint(%{enabled_notification_types: enabled_notification_types})
  end

  @spec disable_notification_type(WebhookEndpoint.t(), binary | [binary]) :: WebhookEndpoint.t()
  def disable_notification_type(%WebhookEndpoint{} = webhook_endpoint, notification_type) do
    notification_types = notification_type |> List.wrap()

    %{enabled_notification_types: enabled_notification_types} =
      webhook_endpoint |> CaptainHook.repo().preload(:enabled_notification_types)

    enabled_notification_types =
      enabled_notification_types
      |> Enum.filter(&(&1.name in notification_types))

    webhook_endpoint
    |> update_webhook_endpoint(%{enabled_notification_types: enabled_notification_types})
  end

  @spec webhook_endpoint_queryable(keyword) :: Ecto.Queryable.t()
  def webhook_endpoint_queryable(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])
    includes = Keyword.get(opts, :includes, [])

    WebhookEndpointQueryable.queryable()
    |> WebhookEndpointQueryable.filter(filters)
    |> WebhookEndpointQueryable.with_preloads(includes)
  end
end
