defmodule CaptainHook.Factory do
  use CaptainHook.Factory.WebhookEndpoint
  use CaptainHook.Factory.WebhookEndpointSecret
  use CaptainHook.Factory.WebhookConversation
  use CaptainHook.Factory.WebhookNotification

  alias CaptainHook.TestRepo

  @spec uuid :: <<_::288>>
  def uuid() do
    Ecto.UUID.generate()
  end

  @spec shortcode_uuid(nil | binary) :: binary
  def shortcode_uuid(prefix \\ nil), do: uuid() |> Shortcode.to_shortcode!(prefix)

  @spec utc_now :: DateTime.t()
  def utc_now(), do: DateTime.utc_now() |> DateTime.truncate(:second)

  @spec add(DateTime.t(), integer, System.time_unit()) :: DateTime.t()
  def add(%DateTime{} = datetime, amount_of_time, time_unit \\ :second) do
    datetime |> DateTime.add(amount_of_time, time_unit)
  end

  @spec params_for(struct) :: map
  def params_for(schema) when is_struct(schema) do
    schema
    |> AntlUtilsEcto.map_from_struct()
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Enum.into(%{})
  end

  @spec params_for(atom, Enum.t()) :: map
  def params_for(factory_name, attributes \\ []) do
    factory_name |> build(attributes) |> params_for()
  end

  @spec build(atom) :: %{:__struct__ => atom, optional(atom) => any}
  def build(factory_name), do: build(factory_name, [])

  @spec insert!(atom, Enum.t()) :: any
  def insert!(factory_name, attributes)
      when is_atom(factory_name) or is_tuple(factory_name) do
    factory_name |> build(attributes) |> insert!()
  end

  @spec insert!(atom | tuple | struct) :: struct
  def insert!(factory_name) when is_atom(factory_name) or is_tuple(factory_name) do
    factory_name |> build([]) |> insert!()
  end

  def insert!(schema) when is_struct(schema), do: schema |> TestRepo.insert!()
end
