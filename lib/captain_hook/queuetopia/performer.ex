defmodule CaptainHook.Queuetopia.Performer do
  @moduledoc false

  use Queuetopia.Performer

  alias Queuetopia.Queue.Job

  alias CaptainHook.Notifier

  @impl true
  @spec perform(Job.t()) :: {:error, binary} | {:ok, any}
  def perform(%Job{action: "notify_endpoint", params: params}) do
    Notifier.send_webhook_notification(params)
  end

  @impl true
  def handle_failed_job!(%Job{
        action: "notify_endpoint",
        params: params,
        attempts: attempts,
        next_attempt_at: next_attempt_at,
        error: error
      }) do
    Notifier.handle_failure!(params, attempts, next_attempt_at, error)

    :ok
  end
end
