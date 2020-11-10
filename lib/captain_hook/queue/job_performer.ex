defmodule CaptainHook.Queue.JobPerformer do
  @behaviour Queuetopia.Jobs.Performer

  alias Queuetopia.Jobs.Job
  alias CaptainHook.Notifier

  @impl true
  @spec perform(Job.t()) :: {:error, binary} | {:ok, any}
  def perform(%Job{action: "notify", params: params, attempts: attempt_number}) do
    Notifier.notify(params, attempt_number)
  end
end
