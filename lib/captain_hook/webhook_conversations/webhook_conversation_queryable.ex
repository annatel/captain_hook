defmodule CaptainHook.WebhookConversations.WebhookConversationQueryable do
  use AntlUtils.Ecto.Queryable,
    base_schema: CaptainHook.WebhookConversations.WebhookConversation
end
