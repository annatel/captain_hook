
defmodule CaptainHook.TestRepo.Migrations.CreateCaptainHookTables do
  use Ecto.Migration

  def up do
    Queuetopia.Migrations.up()
    CaptainHook.Migrations.up()
  end

  def down do
    Queuetopia.Migrations.down()
    CaptainHook.Migrations.down()
  end
end
