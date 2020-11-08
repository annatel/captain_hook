defmodule CaptainHook.WebhookSecrets.WebhookSecretQueryable do
  use AntlUtilsEcto.Queryable,
    base_schema: CaptainHook.WebhookSecrets.WebhookSecret

  @spec filter_by_period_status(
          Ecto.Queryable.t(),
          :ended | :ongoing | :scheduled | nil | [:ended | :ongoing | :scheduled],
          DateTime.t()
        ) :: Ecto.Queryable.t()
  def filter_by_period_status(queryable, nil, _) do
    queryable
  end

  def filter_by_period_status(queryable, period_status, %DateTime{} = period_status_at) do
    queryable
    |> AntlUtilsEcto.Query.where_period_status(
      period_status,
      :started_at,
      :ended_at,
      period_status_at
    )
  end
end
