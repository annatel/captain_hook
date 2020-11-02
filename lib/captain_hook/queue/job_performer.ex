defmodule CaptainHook.Queue.JobPerformer do
  @behaviour Queuetopia.Jobs.Performer

  alias Queuetopia.Jobs.Job
  alias CaptainHook.Sender

  @impl true
  @spec perform(Job.t()) :: {:error, binary} | {:ok, any}
  def perform(%Job{action: "sending_an_event", params: params, attempts: attempt_number}) do
    Sender.perform_send(params, attempt_number)
  end
end
