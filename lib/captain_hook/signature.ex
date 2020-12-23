defmodule CaptainHook.Signature do
  @schema "v1"

  @spec sign(binary, integer, binary | [binary]) :: binary
  def sign(payload, timestamp, secrets) when is_binary(payload) do
    signature = "t=#{timestamp},"

    secrets
    |> List.wrap()
    |> Enum.reduce(signature, fn secret, acc ->
      acc <> "#{@schema}=#{hash(payload, timestamp, secret)},"
    end)
    |> String.trim(",")
  end

  defp hash(payload, timestamp, secret) do
    :crypto.hmac(:sha256, secret, "#{timestamp}.#{payload}")
    |> Base.encode16(case: :lower)
  end
end
