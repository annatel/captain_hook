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
      %{
        id: CaptainHookFinch,
        start: {Finch, :start_link, [[name: CaptainHookFinch]]}
      },
      %{
        id: CaptainHookFinchInsecure,
        start:
          {Finch, :start_link,
           [
             [
               name: CaptainHookFinchInsecure,
               pools: %{
                 default: [conn_opts: [transport_opts: [verify: :verify_none]]]
               }
             ]
           ]}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
