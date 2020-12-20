defmodule CaptainHook.Queue.JobPerformer do
  @behaviour Queuetopia.Jobs.Performer

  alias Queuetopia.Jobs.Job
  alias CaptainHook.Notifier

  @impl true
  @spec perform(Job.t()) :: {:error, binary} | {:ok, any}
  def perform(%Job{action: "notify_endpoint", params: params, attempts: attempt_number}) do
    Notifier.send_notification(params, attempt_number)
  end
end
