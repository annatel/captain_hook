defmodule CaptainHook.Factory do
  use CaptainHook.Factory.WebhookEndpoint
  use CaptainHook.Factory.WebhookSecret
  use CaptainHook.Factory.WebhookConversation

  alias CaptainHook.TestRepo

  @spec uuid :: <<_::288>>
  def uuid() do
    Ecto.UUID.generate()
  end

  def utc_now() do
    DateTime.utc_now() |> DateTime.truncate(:second)
  end

  def params_for(%_{} = schema) when is_map(schema) do
    schema
    |> AntlUtilsEcto.map_from_struct()
    |> Enum.filter(fn {_, v} -> v end)
    |> Enum.into(%{})
  end

  def params_for(factory_name, attributes \\ []) when is_atom(factory_name) do
    factory_name
    |> build(attributes)
    |> AntlUtilsEcto.map_from_struct()
    |> Enum.filter(fn {_, v} -> v end)
    |> Enum.into(%{})
  end

  def build(factory_name, attributes) do
    factory_name |> build() |> struct!(attributes)
  end

  def insert!(factory_name, attributes \\ []) do
    factory_name |> build(attributes) |> TestRepo.insert!()
  end
end
