defmodule CaptainHook.TestRepo.Migrations.CreateCaptainHookTables do
  use Ecto.Migration

  def up do
    CaptainHook.Migrations.V1.CaptainHook.up()
    CaptainHook.Migrations.V1.Queuetopia.up()

    CaptainHook.Migrations.V2.CaptainHook.up()
    CaptainHook.Migrations.V2.Queuetopia.up()

    CaptainHook.Migrations.V3.CaptainHook.up()
    CaptainHook.Migrations.V3.Queuetopia.up()

    # CaptainHook.Migrations.V2.CaptainHook.Data.up()
  end

  def down do
    CaptainHook.Migrations.V1.CaptainHook.down()
    CaptainHook.Migrations.V1.Queuetopia.down()
    CaptainHook.Migrations.V2.CaptainHook.down()
    CaptainHook.Migrations.V2.Queuetopia.down()
    CaptainHook.Migrations.V3.Queuetopia.down()
  end
end
