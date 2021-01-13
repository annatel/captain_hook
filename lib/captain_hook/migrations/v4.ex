defmodule CaptainHook.Migrations.V4 do
  @moduledoc false

  use Ecto.Migration

  def up do
    Queuetopia.Migrations.V3.up()
  end

  def down do
    Queuetopia.Migrations.V3.down()
  end
end
