Application.ensure_all_started(:mox)

{:ok, _pid} = CaptainHook.TestRepo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(CaptainHook.TestRepo, :manual)

ExUnit.start()
