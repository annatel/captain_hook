
defmodule CaptainHook.TestRepo.Migrations.CreateCaptainHookTables do
  use Ecto.Migration

  def up do
    CaptainHook.Migrations.V1.up()
    CaptainHook.Migrations.V2.up()
    CaptainHook.Migrations.V3.up()
    CaptainHook.Migrations.V4.up()

    CaptainHook.Migrations.V2Data.up()
  end

  def down do
    CaptainHook.Migrations.V1.down()
    CaptainHook.Migrations.V2.down()
    CaptainHook.Migrations.V3.down()
    CaptainHook.Migrations.V4.down()
  end
end
