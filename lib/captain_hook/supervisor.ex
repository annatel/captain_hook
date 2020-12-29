defmodule CaptainHook.Supervisor do
  @moduledoc false

  use Supervisor

  @default_poll_interval 60 * 1_000

  def start_link(opts) when is_list(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    poll_interval = Keyword.get(opts, :poll_interval, @default_poll_interval)

    children = [
      {CaptainHook.Queue, [poll_interval: poll_interval]},
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
