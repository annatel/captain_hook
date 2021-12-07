defmodule CaptainHook.Test.Factories do
  @moduledoc false

  alias CaptainHook.WebhookEndpoints.WebhookEndpoint
  alias CaptainHook.WebhookEndpoints.Secrets
  alias CaptainHook.WebhookEndpoints.Secrets.WebhookEndpointSecret
  alias CaptainHook.WebhookNotifications.WebhookNotification
  alias CaptainHook.WebhookConversations.WebhookConversation

  @spec build(
          :webhook_conversation
          | :webhook_endpoint
          | :webhook_endpoint_secret
          | :webhook_notification,
          Enum.t()
        ) :: struct
  def build(:webhook_endpoint, attrs) do
    %WebhookEndpoint{
      created_at: utc_now(),
      enabled_notification_patterns: [%{pattern: "+"}],
      headers: %{},
      livemode: true,
      url: "url_#{System.unique_integer()}"
    }
    |> put_owner_id()
    |> struct!(attrs)
  end

  def build(:webhook_endpoint_secret, attrs) do
    %WebhookEndpointSecret{
      started_at: utc_now(),
      secret: Secrets.generate_secret(),
      is_main: true
    }
    |> struct!(attrs)
  end

  def build(:webhook_notification, attrs) do
    %WebhookNotification{
      created_at: utc_now(),
      data: %{},
      ref: "ref_#{System.unique_integer()}",
      resource_id: "resource_id",
      resource_object: "resource_object",
      sequence: System.unique_integer([:positive])
    }
    |> struct!(attrs)
  end

  def build(:webhook_conversation, attrs) do
    %WebhookConversation{
      sequence: System.unique_integer([:positive]),
      requested_at: utc_now(),
      request_url: "request_url",
      request_headers: %{"Header-Key" => "header value"},
      request_body: "{}",
      http_status: 200,
      response_body: "response body",
      status: WebhookConversation.statuses().succeeded
    }
    |> struct!(attrs)
  end

  defp put_owner_id(webhook_endpoint) do
    owner_id_value =
      if elem(CaptainHook.owner_id_field(:migration), 1) == :binary_id,
        do: Ecto.UUID.generate(),
        else: System.unique_integer([:positive])

    webhook_endpoint
    |> Map.put(elem(CaptainHook.owner_id_field(:schema), 0), owner_id_value)
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

  def insert!(schema) when is_struct(schema),
    do: schema |> CaptainHook.repo().insert!()

  defp utc_now(), do: DateTime.utc_now() |> DateTime.truncate(:second)
end
