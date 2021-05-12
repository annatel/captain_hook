defmodule CaptainHook.WebhookNotifications.WebhookNotificationQueryable do
  @moduledoc false

  use AntlUtilsEcto.Queryable,
    base_schema: CaptainHook.WebhookNotifications.WebhookNotification

  import Ecto.Query, only: [preload: 2, select: 2]

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

  defp preload_webhook_endpoint(queryable) do
    queryable |> preload(:webhook_endpoint)
  end

  @spec select_fields(Ecto.Queryable.t(), nil | list) :: Ecto.Queryable.t()
  def select_fields(queryable, nil), do: queryable
  def select_fields(queryable, fields) when is_list(fields), do: queryable |> select(^fields)
end
