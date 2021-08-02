defmodule CaptainHook.Queuetopia.Performer do
  @moduledoc false

  use Queuetopia.Performer

  alias Queuetopia.Queue.Job

  alias CaptainHook.Notifier

  @impl true
  @spec perform(Job.t()) :: {:error, binary} | {:ok, any}
  def perform(%Job{action: "notify_endpoint", params: params} = job) do
    Notifier.send_webhook_notification(params, performer: __MODULE__, job: job)
  end
end
