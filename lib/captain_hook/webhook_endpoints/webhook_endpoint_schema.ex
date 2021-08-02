defmodule CaptainHook.WebhookEndpoints.WebhookEndpointSchema do
  defmacro configurable_fields() do
    quote do
      import Ecto.Schema

      field(
        elem(CaptainHook.owner_id_field(:schema), 0),
        elem(CaptainHook.owner_id_field(:schema), 1),
        elem(CaptainHook.owner_id_field(:schema), 2)
      )
    end
  end

  defmacro __using__(_) do
    quote do
      use Ecto.Schema

      import CaptainHook.WebhookEndpoints.WebhookEndpointSchema

      defp validate_configurable_fields(%Ecto.Changeset{} = changeset, attrs) do
        required_fields = [elem(CaptainHook.owner_id_field(:schema), 0)]

        changeset
        |> Ecto.Changeset.cast(attrs, required_fields)
        |> Ecto.Changeset.validate_required(required_fields)
      end
    end
  end
end
