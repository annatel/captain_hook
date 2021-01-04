defmodule CaptainHook.TestRepo.Migrations.CaptainHookV3 do
  use Ecto.Migration

  def change do
    CaptainHook.Migrations.V3.up()
  end
end
