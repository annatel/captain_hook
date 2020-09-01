
defmodule CaptainHook.TestRepo.Migrations.CreateCaptainHookTables do
  use Ecto.Migration

  def up do
    CaptainHook.Migrations.V1.up()
  end

  def down do
    CaptainHook.Migrations.V1.down()
  end
end
