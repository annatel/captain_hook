defmodule CaptainHook.WebhookSecrets.WebhookSecretQueryable do
  use AntlUtilsEcto.Queryable,
    base_schema: CaptainHook.WebhookSecrets.WebhookSecret
end
