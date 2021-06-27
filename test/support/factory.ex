defmodule CaptainHook.Factory do
  use AntlUtilsEcto.Factory, repo: CaptainHook.TestRepo

  use CaptainHook.Factory.WebhookEndpoint
  use CaptainHook.Factory.WebhookEndpointSecret
  use CaptainHook.Factory.WebhookConversation
  use CaptainHook.Factory.WebhookNotification
end
