defmodule CaptainHook.SignatureTest do
  use ExUnit.Case, async: true
  use CaptainHook.DataCase

  alias CaptainHook.Signature

  test "signs a payload correctly" do
    payload = "{\"data\": \"a-sample-payload\"}"
    secret = "a-secret"
    timestamp = 1_595_960_507

    signature = "t=1595960507,v1=10f65f2a9dfc9325b59109e7ee631ea11c419457f0b292299c770b137393b0ce"

    assert ^signature = Signature.sign(payload, timestamp, secret)
  end
end
