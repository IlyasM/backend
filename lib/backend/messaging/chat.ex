defmodule Backend.Messaging.Chat do
  use Ecto.Schema
  import Ecto.Changeset
  use BackendWeb, :db

  schema "chats" do
    many_to_many(
      :users,
      User,
      join_through: UserChat
    )

    has_many(:messages, Message)

    timestamps()
  end

  @doc false
  def changeset(chat, attrs) do
    chat
    |> cast(attrs, [])
  end
end

# first user goes to conversation channel, chat gets created automagically if not existed before
#
#
