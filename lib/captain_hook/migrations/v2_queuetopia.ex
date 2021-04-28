defmodule CaptainHook.Migrations.V2.Queuetopia do
  @moduledoc false

  use Ecto.Migration

  def up do
    Queuetopia.Migrations.V2.up()
  end

  def down do
    :noop
  end
end
