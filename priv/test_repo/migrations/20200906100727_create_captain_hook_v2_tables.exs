defmodule CaptainHook.TestRepo.Migrations.CreateCaptainHookV2Tables do
  use Ecto.Migration

  def up do
    CaptainHook.Migrations.V2.up()
  end

  def down do
    CaptainHook.Migrations.V2.down()
  end
end
