defmodule Backend.Messaging.UserChat do
  use Ecto.Schema

  schema "users_chats" do
    field(:user_id, :id)
    field(:chat_id, :id)

    timestamps()
  end
end
