defmodule CaptainHook.Signature do
  @schema "v1"
  @valid_period_in_seconds 300

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

  @spec verify(binary, binary, binary, keyword) :: :ok | {:error, binary}
  def verify(header, payload, secret, opts \\ []) do
    with {:ok, timestamp, hashes} <- parse_signature_header(header, @schema) do
      current_timestamp = Keyword.get(opts, :system, System).system_time(:second)
      expected_hash = hash(payload, timestamp, secret)

      hashes
      |> Enum.map(&Plug.Crypto.secure_compare(&1, expected_hash))

      cond do
        timestamp + @valid_period_in_seconds < current_timestamp ->
          {:error, "signature is too old"}

        Enum.all?(hashes, &(Plug.Crypto.secure_compare(&1, expected_hash) == false)) ->
          {:error, "signature is incorrect"}

        true ->
          :ok
      end
    end
  end

  defp hash(payload, timestamp, secret) do
    :crypto.hmac(:sha256, secret, "#{timestamp}.#{payload}")
    |> Base.encode16(case: :lower)
  end

  @spec parse_signature_header(binary, binary) ::
          {:error, binary} | {:ok, timestamp :: integer, hashes :: [binary]}
  def parse_signature_header(signature, schema) do
    parsed =
      for pair <- String.split(signature, ","),
          destructure([key, value], String.split(pair, "=", parts: 2)),
          do: {key, value},
          into: []

    with [{"t", timestamp} | hashes] <- parsed,
         {timestamp, ""} <- Integer.parse(timestamp),
         {@schema, _} <- hashes |> List.first() do
      hashes =
        hashes
        |> Enum.filter(fn {key, _value} -> key == schema end)
        |> Enum.map(fn {_key, value} -> value end)

      {:ok, timestamp, hashes}
    else
      _ -> {:error, "signature is in a wrong format or is missing v1 schema"}
    end
  end
end
