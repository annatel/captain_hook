# CaptainHook

Ordered webhooks notification

## Installation

CaptainHook is published on [Hex](https://hex.pm/packages/captain_hook).  
The package can be installed by adding `captain_hook` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:captain_hook, "~> 0.1.0"}
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

The docs can be found at [https://hexdocs.pm/captain_hook](https://hexdocs.pm/captain_hook).