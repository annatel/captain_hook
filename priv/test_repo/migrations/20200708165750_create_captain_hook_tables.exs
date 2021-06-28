
defmodule CaptainHook.TestRepo.Migrations.CreateCaptainHookTables do
  use Ecto.Migration

  def up do
    Queuetopia.Migrations.up()
    Padlock.Mutexes.Migrations.V1.up()
    CaptainHook.Migrations.up()
  end

  def down do
    Queuetopia.Migrations.down()
    Padlock.Mutexes.Migrations.V1.down()
    CaptainHook.Migrations.down()
  end
end
