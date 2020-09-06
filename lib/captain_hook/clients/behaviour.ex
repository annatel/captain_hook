defmodule CaptainHook.Clients.Behaviour do
  @callback call(url :: binary, params :: map(), headers :: map()) ::
              CaptainHook.Clients.Response.t()
end
