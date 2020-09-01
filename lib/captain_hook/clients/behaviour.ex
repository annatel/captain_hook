defmodule CaptainHook.Clients.Behaviour do
  @callback call(url :: binary, params :: map()) :: CaptainHook.Clients.Response.t()
end
