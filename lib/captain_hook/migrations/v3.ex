defmodule CaptainHook.Migrations.V3 do
  @moduledoc false

  use Ecto.Migration

  def up do
    Queuetopia.Migrations.V2.up()
  end

  def down do
  end
end
