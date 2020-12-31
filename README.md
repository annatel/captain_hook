# CaptainHook

[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/annatel/captain_hook/CI?cacheSeconds=3600&style=flat-square)](https://github.com/annatel/captain_hook/actions) [![GitHub issues](https://img.shields.io/github/issues-raw/annatel/captain_hook?style=flat-square&cacheSeconds=3600)](https://github.com/annatel/captain_hook/issues) [![License](https://img.shields.io/badge/license-MIT-brightgreen.svg?cacheSeconds=3600?style=flat-square)](http://opensource.org/licenses/MIT) [![Hex.pm](https://img.shields.io/hexpm/v/captain_hook?style=flat-square)](https://hex.pm/packages/captain_hook) [![Hex.pm](https://img.shields.io/hexpm/dt/captain_hook?style=flat-square)](https://hex.pm/packages/captain_hook)

Ordered signed webhook notifications. Support multiple endpoints for each webhook.

## Installation

CaptainHook is published on [Hex](https://hex.pm/packages/captain_hook).  
The package can be installed by adding `captain_hook` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:captain_hook, "~> 1.6.0"}
  ]
end
```

After the packages are installed you must create a database migration for each versionto add the captain_hook tables to your database:

```elixir
defmodule MyApp.Repo.Migrations.AddCaptainHookV1Tables do
  use Ecto.Migration

  def up do
    CaptainHook.Migrations.V1.up()
  end

  def down do
    CaptainHook.Migrations.V1.down()
  end
end

defmodule MyApp.Repo.Migrations.AddCaptainHookV2Tables do
  use Ecto.Migration

  def up do
    CaptainHook.Migrations.V2.up()
    CaptainHook.Migrations.V2Data.up()
  end

  def down do
    CaptainHook.Migrations.V2.down()
  end
end
```

This will run all of CaptainHook's versioned migrations for your database. Migrations between versions are idempotent and will never change after a release. As new versions are released you may need to run additional migrations.

Now, run the migration to create the table:

```sh
mix ecto.migrate
```

## Usage

```elixir
webhook_endpoint = CaptainHook.create_webhook_endpoint(%{
  webhook: "my_webhook_name", 
  url: "https://webhook.site/538bb308-4dd8-4008-a19b-4e4a5758ef29",
  livemode: true,
  enabled_notification_types: [%{name: "*"}]
})

# Get the webhook_endpoint secret in order to verify the webhook signature
%CaptainHook.WebhookEndpoint{secret: secret} = 
  CaptainHook.get_webhook_endpoint(webhook_endpoint.id, includes: [:secret])

# Notify - it will enqueue the notification and send it in its turn
{:ok, CaptainHook.WebhookNotification{} = webhook_notification} = 
  CaptainHook.notify(
    "my_webhook_name", 
    true, 
    "notification_type", 
    %{"my" => "data", "to" => "report"}
  )
```

## CaptainHook client

Want to verify the authenticity of a captain_hook request ? you can use the [CaptainHookClient](https://github.com/annatel/captain_hook_client).

The docs can be found at [https://hexdocs.pm/captain_hook](https://hexdocs.pm/captain_hook).
