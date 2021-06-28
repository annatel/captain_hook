defmodule CaptainHook.Extensions.Ecto.Query do
  def exclude_where_field(%Ecto.Query{wheres: wheres} = query, field) do
    wheres =
      wheres
      |> Enum.reject(fn %{expr: {_, _, [{{_, _, [_, current_field]}, _, _}]}} ->
        current_field == field
      end)

    %{query | wheres: wheres}
  end
end
