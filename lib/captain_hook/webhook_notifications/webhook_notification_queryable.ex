defmodule CaptainHook.WebhookNotifications.WebhookNotificationQueryable do
  @moduledoc false

  use AntlUtilsEcto.Queryable,
    base_schema: CaptainHook.WebhookNotifications.WebhookNotification

  import Ecto.Query, only: [preload: 2, select: 2]

  alias CaptainHook.WebhookEndpoints

  @spec with_preloads(Ecto.Queryable.t(), keyword) :: Ecto.Queryable.t()
  def with_preloads(queryable, includes) when is_list(includes) do
    includes
    |> Enum.reduce(queryable, fn include, queryable ->
      queryable |> with_preload(include)
    end)
  end

  defp with_preload(queryable, :webhook_endpoint) do
    queryable |> preload_webhook_endpoint()
  end

  defp with_preload(queryable, {:webhook_endpoint, includes}) do
    queryable |> preload_webhook_endpoint(includes: includes)
  end

  defp preload_webhook_endpoint(queryable, opts \\ []) do
    includes = opts |> Keyword.get(:includes, [])

    webhook_endpoint_query =
      [includes: includes]
      |> WebhookEndpoints.webhook_endpoint_queryable()
      |> Ecto.Queryable.to_query()

    queryable |> preload(webhook_endpoint: ^webhook_endpoint_query)
  end

  @spec select_fields(Ecto.Queryable.t(), nil | list) :: Ecto.Queryable.t()
  def select_fields(queryable, nil), do: queryable
  def select_fields(queryable, fields) when is_list(fields), do: queryable |> select(^fields)
end
