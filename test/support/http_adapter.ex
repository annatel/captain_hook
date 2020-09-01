defmodule CaptainHook.HttpAdapter do
  @moduledoc false

  @type url :: binary
  @type headers :: [{atom, binary}] | [{binary, binary}] | %{binary => binary}
  @type body :: binary | {:form, [{atom, any}]} | {:file, binary}
  @type options :: Keyword.t()

  @callback post(url, term, headers, options) ::
              {:ok, HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()}
              | {:error, HTTPoison.Error.t()}
end
