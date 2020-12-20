defmodule CaptainHook.WebhookNotifications.WebhookNotificationQueryable do
  use AntlUtilsEcto.Queryable,
    base_schema: CaptainHook.WebhookNotifications.WebhookNotification

  import Ecto.Query, only: [select: 2]

  @spec select_fields(Ecto.Queryable.t(), nil | list) :: Ecto.Queryable.t()
  def select_fields(queryable, nil), do: queryable
  def select_fields(queryable, fields) when is_list(fields), do: queryable |> select(^fields)
end
