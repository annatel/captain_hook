defmodule CaptainHook.Clients.Behaviour do
  @callback call(url :: binary, params :: map(), headers :: map(), keyword()) ::
              CaptainHook.Clients.Response.t()
end
