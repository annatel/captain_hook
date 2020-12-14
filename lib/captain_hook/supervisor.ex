defmodule CaptainHook.Supervisor do
  @moduledoc """
  Documentation for CaptainHook.Supervisor
  """

  use Supervisor

  def start_link(opts) when is_list(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      CaptainHook.Queue,
      {Finch, name: CaptainHookFinch}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
