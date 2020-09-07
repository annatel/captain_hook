defmodule CaptainHook.Supervisor do
  @moduledoc """
  Documentation for CaptainHook.Supervisor
  """

  use Supervisor

  @default_poll_interval 60 * 1_000

  def start_link(opts) when is_list(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    poll_interval = Keyword.get(opts, :poll_interval, @default_poll_interval)

    children = [
      {CaptainHook.Queue, [repoll_after_job_performed?: true, poll_interval: poll_interval]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
