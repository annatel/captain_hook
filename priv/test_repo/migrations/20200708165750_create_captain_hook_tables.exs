
defmodule CaptainHook.TestRepo.Migrations.CreateCaptainHookTables do
  use Ecto.Migration

  def up do
    Queuetopia.Migrations.up(from_version: 0, to_version: 3)
    CaptainHook.Migrations.up(from_version: 0, to_version: 3)
  end

  def down do
    Queuetopia.Migrations.down(from_version: 3, to_version: 0)
    CaptainHook.Migrations.down(from_version: 3, to_version: 0)
  end
end
