defmodule CaptainHook.Queuetopia.Performer do
  @moduledoc false

  @behaviour Queuetopia.Performer

  alias Queuetopia.Queue.Job
  alias CaptainHook.Notifier

  @impl true
  @spec perform(Job.t()) :: {:error, binary} | {:ok, any}
  def perform(%Job{action: "notify_endpoint", params: params}) do
    Notifier.send_webhook_notification(params)
  end
end
