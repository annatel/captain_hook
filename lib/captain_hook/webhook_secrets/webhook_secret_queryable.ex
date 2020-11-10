defmodule CaptainHook.WebhookSecrets.WebhookSecretQueryable do
  use AntlUtilsEcto.Queryable,
    base_schema: CaptainHook.WebhookSecrets.WebhookSecret

  @spec filter_by_status(
          Ecto.Queryable.t(),
          nil | AntlUtilsEcto.Query.status() | list(AntlUtilsEcto.Query.status()),
          DateTime.t()
        ) :: Ecto.Queryable.t()
  def filter_by_status(queryable, nil, _) do
    queryable
  end

  def filter_by_status(queryable, status, %DateTime{} = datetime) do
    queryable
    |> AntlUtilsEcto.Query.where_period_status(status, :started_at, :ended_at, datetime)
  end
end
